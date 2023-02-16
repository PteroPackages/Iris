use serde::{
    de::{self, value::MapAccessDeserializer, Visitor},
    Deserialize,
};
use std::{
    fmt::{self, Formatter},
    fs::read,
    path::Path,
};
use url::Url;

use super::error::{Error, ErrorKind};

#[derive(Debug)]
pub struct Config {
    pub url: Url,
    pub key: String,
    pub data: String,
    pub servers: Vec<String>,
}

impl<'de> Deserialize<'de> for Config {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        deserializer.deserialize_map(ConfigVisitor)
    }
}

#[derive(Deserialize)]
struct RawConfig {
    url: String,
    key: String,
    data: String,
    servers: Vec<String>,
}

struct ConfigVisitor;

impl<'de> Visitor<'de> for ConfigVisitor {
    type Value = Config;

    fn expecting(&self, formatter: &mut Formatter) -> fmt::Result {
        formatter.write_str("a map of config fields")
    }

    fn visit_map<A>(self, map: A) -> Result<Self::Value, A::Error>
    where
        A: de::MapAccess<'de>,
    {
        let des = MapAccessDeserializer::new(map);
        let cfg = RawConfig::deserialize(des)?;
        let url =
            Url::parse(&cfg.url).map_err(|_| de::Error::custom("could not parse url value"))?;

        Ok(Config {
            url,
            key: cfg.key,
            data: cfg.data,
            servers: cfg.servers,
        })
    }
}

pub fn load() -> Result<Config, Error> {
    let p = match get_path() {
        Some(v) => Path::new(v),
        None => {
            return Err(Error {
                kind: ErrorKind::ConfigFailedLoad,
                source: None,
            })
        }
    };

    if !p.exists() {
        return Err(Error {
            kind: ErrorKind::ConfigNotFound,
            source: None,
        });
    }

    let buf = read(p).map_err(|e| Error {
        kind: ErrorKind::ConfigFailedLoad,
        source: Some(Box::new(e)),
    })?;

    serde_yaml::from_slice(&buf).map_err(|e| Error {
        kind: ErrorKind::ConfigFailedLoad,
        source: Some(Box::new(e)),
    })
}

#[cfg(target_family = "unix")]
fn get_path() -> Option<&'static str> {
    Some("/etc/iris/config.yml")
}

#[cfg(target_family = "windows")]
fn get_path() -> Option<&'static str> {
    todo!()
}
