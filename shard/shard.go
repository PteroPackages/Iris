package shard

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/gorilla/websocket"
	croc "github.com/parkervcp/crocgodyl"
)

type Payload struct {
	Event string   `json:"event"`
	Args  []string `json:"args"`
}

type Shard struct {
	client *croc.Client
	cancel chan struct{}
	uuid   string
	dpath  string
	lpath  string
	data   *bytes.Buffer
	log    *bytes.Buffer
}

func (s *Shard) UUID() string {
	return s.uuid
}

func (s *Shard) Launch() error {
	a, err := s.client.GetServerWebSocket(s.uuid)
	if err != nil {
		return err
	}

	conn, _, err := websocket.DefaultDialer.Dial(a.Socket, http.Header{"Origin": []string{s.client.PanelURL}})
	if err != nil {
		return err
	}

	go func() {
		<-s.cancel
		conn.WriteMessage(websocket.CloseNormalClosure, nil)
		_ = conn.Close()
	}()

	go func() {
		defer s.save()

		buf, err := json.Marshal(&Payload{Event: "auth", Args: []string{a.Token}})
		if err != nil {
			// need a way to log this somehow
			return
		}
		conn.WriteMessage(websocket.TextMessage, buf)

		for {
			mtype, msg, err := conn.ReadMessage()
			if err != nil {
				s.log.WriteString(fmt.Sprintf("error reading message: %s\n", err))
				continue
			}

			switch mtype {
			case websocket.CloseMessage:
				_ = conn.Close()
				return
			case websocket.TextMessage:
				s.data.Write(msg)
			default:
				continue
			}
		}
	}()

	return nil
}

func (s *Shard) save() error {
	fd, err := os.Open(s.dpath)
	if err != nil {
		return err
	}

	defer fd.Close()
	fd.Write(s.data.Bytes())

	fl, err := os.Open(s.lpath)
	if err != nil {
		return err
	}

	defer fl.Close()
	fl.Write(s.log.Bytes())

	return nil
}
