use futures_util::{SinkExt, StreamExt};
use hyper::{
    body::{aggregate, Body, Buf},
    client::{Client, HttpConnector},
    header::{HeaderValue, ACCEPT, CONTENT_TYPE, ORIGIN},
    upgrade::{self, Upgraded},
    Request, StatusCode,
};
use hyper_tls::HttpsConnector;
use serde::{Deserialize, Serialize};
use std::{fmt::Write, fs::File};
use tokio::io::AsyncWriteExt;
use tokio_tungstenite::{
    tungstenite::{protocol::Role, Message},
    WebSocketStream,
};
use url::Url;

use super::error::{Error, ErrorKind};

#[derive(Debug)]
pub struct Server<'a> {
    id: String,
    url: Url,
    conn: &'a Client<HttpsConnector<HttpConnector>>,
    log: Vec<u8>,
}

impl<'a> Server<'a> {
    pub fn new(
        id: String,
        url: Url,
        conn: &'a Client<HttpsConnector<HttpConnector>>,
        path: String,
    ) -> Result<Self, Error> {
        File::create(path)?;

        Ok(Self {
            id,
            url,
            conn,
            log: Default::default(),
        })
    }

    pub fn id(&self) -> &String {
        &self.id
    }

    pub async fn connect(&mut self) -> Result<(), Error> {
        let req = Request::builder()
            .uri(format!(
                "{}/api/client/servers/{}/websocket",
                self.url, self.id
            ))
            .header(
                CONTENT_TYPE,
                HeaderValue::from_str("application/json").unwrap(),
            )
            .header(ACCEPT, HeaderValue::from_str("application/json").unwrap())
            .body(Body::empty())?;

        let auth = match self.conn.request(req).await {
            Ok(r) => {
                if r.status() != StatusCode::OK {
                    return Err(Error {
                        kind: ErrorKind::RequestFailed,
                        source: None,
                    });
                }

                let buf = aggregate(r).await?;
                serde_json::from_reader::<_, SocketAuth>(buf.reader())?
            }
            Err(e) => {
                return Err(Error {
                    kind: ErrorKind::RequestFailed,
                    source: Some(Box::new(e)),
                })
            }
        };

        let mut wsr = Request::builder()
            .uri(auth.data.socket)
            .header(
                ORIGIN,
                HeaderValue::from_str(self.url.domain().unwrap()).unwrap(),
            )
            .body(Body::empty())?;

        match upgrade::on(&mut wsr).await {
            Ok(up) => self.handle_connection(
                WebSocketStream::from_raw_socket(up, Role::Client, None).await,
                auth.data.token,
            ),
            Err(e) => {
                return Err(Error {
                    kind: ErrorKind::UpgradeFailed,
                    source: Some(Box::new(e)),
                })
            }
        }
        .await;

        Ok(())
    }

    async fn handle_connection(&mut self, stream: WebSocketStream<Upgraded>, token: String) {
        let (mut outgoing, mut incoming) = stream.split();

        if let Err(e) = outgoing.send(Payload::from("auth", &[&token])).await {
            eprintln!("failed to send auth token: {e}");
            return;
        }

        for msg in (incoming.next().await).into_iter().flatten() {
            if msg.is_binary() {
                continue;
            }

            let data = match serde_json::from_slice::<SocketMessage>(&msg.into_data()) {
                Ok(d) => d,
                Err(_) => continue, // discard for now
            };

            match data.event {
                SocketEvent::AuthSuccess => (),
                SocketEvent::ConsoleOutput => {
                    // if let Err(e) = ...
                    if AsyncWriteExt::write(&mut self.log, &data.collect())
                        .await
                        .is_err()
                    {
                        continue; // TODO: log this
                    }
                }
            }
        }
    }
}

#[derive(Debug, Serialize)]
struct Payload {
    pub event: String,
    pub args: Vec<String>,
}

impl Payload {
    fn new(event: &str, args: &[&str]) -> Self {
        Self {
            event: event.to_string(),
            args: args.iter().map(ToString::to_string).collect(),
        }
    }

    pub fn from(event: &str, args: &[&str]) -> Message {
        let p = Self::new(event, args);
        let d = serde_json::to_string(&p).unwrap();

        Message::text(d)
    }
}

#[derive(Debug, Deserialize)]
struct SocketAuthInner {
    pub socket: String,
    pub token: String,
}

#[derive(Debug, Deserialize)]
struct SocketAuth {
    pub data: SocketAuthInner,
}

#[derive(Debug, Deserialize)]
enum SocketEvent {
    AuthSuccess,
    ConsoleOutput,
}

#[derive(Debug, Deserialize)]
struct SocketMessage {
    pub event: SocketEvent,
    pub data: Vec<String>,
}

impl SocketMessage {
    pub fn collect(&self) -> Vec<u8> {
        let mut s = self.data.join(" ");
        s.write_char('\n').unwrap();

        s.as_bytes().to_owned()
    }
}