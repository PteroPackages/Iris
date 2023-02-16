use clap::{Parser, Subcommand};
use hyper::Client;
use hyper_tls::HttpsConnector;
use std::path::Path;

mod config;
mod error;
mod server;

use self::server::Server;

#[derive(Parser)]
#[command(author, version, about)]
struct Cli {
    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Subcommand)]
enum Command {
    Version,
    Run,
}

#[tokio::main]
async fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Some(Command::Version) => println!("iris version 0.1.0"),
        Some(Command::Run) => {
            if let Err(e) = run().await {
                eprintln!("{e}");
            }
        }
        None => (),
    }
}

async fn run() -> Result<(), error::Error> {
    let cfg = config::load()?;
    let root = Path::new(&cfg.data);
    let conn = Client::builder().build(HttpsConnector::new());
    let mut servers = Vec::<Server>::new();

    for id in cfg.servers {
        let p = root.join(&id).into_os_string().into_string().unwrap();
        match Server::new(id, cfg.url.clone(), &conn, p) {
            Ok(s) => servers.push(s),
            Err(_) => continue, // discard for now
        };
    }

    for mut server in servers {
        if let Err(e) = server.connect().await {
            eprintln!("{e}")
        }
    }

    Ok(())
}
