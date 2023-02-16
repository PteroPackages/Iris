use std::{
    error,
    fmt::{Display, Formatter, Result as FmtResult},
    io,
};

#[derive(Debug)]
pub struct Error {
    pub(super) kind: ErrorKind,
    #[allow(dead_code)]
    pub(super) source: Option<Box<dyn error::Error + Send + Sync>>,
}

impl Display for Error {
    fn fmt(&self, f: &mut Formatter<'_>) -> FmtResult {
        match &self.kind {
            ErrorKind::ConfigFailedLoad => f.write_str("the configuration could not be loaded"),
            ErrorKind::ConfigNotFound => f.write_str("the configuration file was not found"),
            ErrorKind::DeserializeFailed => {
                f.write_str("failed to deserialize json or yaml object")
            }
            ErrorKind::FileError => f.write_str("an unknown file system error occured"),
            ErrorKind::RequestFailed => f.write_str("an unexpected request error occured"),
            ErrorKind::UpgradeFailed => {
                f.write_str("failed to upgrade the request to a websocket connection")
            }
        }
    }
}

impl error::Error for Error {}

impl From<io::Error> for Error {
    fn from(e: io::Error) -> Self {
        Self {
            kind: ErrorKind::FileError,
            source: Some(Box::new(e)),
        }
    }
}

impl From<hyper::Error> for Error {
    fn from(e: hyper::Error) -> Self {
        Self {
            kind: ErrorKind::RequestFailed,
            source: Some(Box::new(e)),
        }
    }
}

impl From<hyper::http::Error> for Error {
    fn from(e: hyper::http::Error) -> Self {
        Self {
            kind: ErrorKind::RequestFailed,
            source: Some(Box::new(e)),
        }
    }
}

impl From<serde_json::Error> for Error {
    fn from(e: serde_json::Error) -> Self {
        Self {
            kind: ErrorKind::DeserializeFailed,
            source: Some(Box::new(e)),
        }
    }
}

impl From<serde_yaml::Error> for Error {
    fn from(e: serde_yaml::Error) -> Self {
        Self {
            kind: ErrorKind::DeserializeFailed,
            source: Some(Box::new(e)),
        }
    }
}

#[derive(Debug)]
pub enum ErrorKind {
    ConfigNotFound,
    ConfigFailedLoad,
    DeserializeFailed,
    RequestFailed,
    UpgradeFailed,
    FileError,
}
