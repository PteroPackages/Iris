package shard

import (
	"bytes"
	"encoding/json"
	"net/http"
	"os"

	"github.com/gorilla/websocket"
	croc "github.com/parkervcp/crocgodyl"
	"github.com/sirupsen/logrus"
)

type Payload struct {
	Event string   `json:"event"`
	Args  []string `json:"args"`
}

func (p *Payload) Bytes() []byte {
	b := &bytes.Buffer{}
	for _, a := range p.Args {
		b.WriteString(a)
	}

	return b.Bytes()
}

type Shard struct {
	client *croc.Client
	cancel chan struct{}
	log    *logrus.Logger
	uuid   string
	path   string
	data   *bytes.Buffer
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
		defer func() {
			f, err := os.Create(s.path)
			if err != nil {
				s.log.WithError(err).WithField("uuid", s.uuid).Error("failed to open shard log file")
				return
			}

			defer f.Close()
			f.Write(s.data.Bytes())
		}()

		buf, err := json.Marshal(&Payload{Event: "auth", Args: []string{a.Token}})
		if err != nil {
			s.log.WithError(err).WithField("uuid", s.uuid).Errorf("failed to marshal json")
			return
		}
		conn.WriteMessage(websocket.TextMessage, buf)

		for {
			_, msg, err := conn.ReadMessage()
			if err != nil {
				if websocket.IsCloseError(err, websocket.CloseNormalClosure, websocket.CloseAbnormalClosure) {
					s.log.WithField("uuid", s.uuid).Debug("socket closed")
					break
				}

				s.log.WithError(err).WithField("uuid", s.uuid).Error("failed to read message")
				continue
			}

			var data *Payload
			if err = json.Unmarshal(msg, &data); err != nil {
				s.log.WithError(err).WithField("uuid", s.uuid).Warn("failed to unmarshal payload")
				continue
			}

			s.data.Write(data.Bytes())
		}
	}()

	return nil
}
