package shard

import (
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/gorilla/websocket"
	croc "github.com/parkervcp/crocgodyl"
)

type payload struct {
	event string
	args  []string
}

type Shard struct {
	client *croc.Client
	cancel chan struct{}
	uuid   string
	path   string
	data   *os.File
	log    *os.File
}

func (s *Shard) UUID() string {
	return s.uuid
}

func (s *Shard) Launch() error {
	defer func() {
		s.data.Close()
		s.log.Close()
	}()

	a, err := s.client.GetServerWebSocket(s.uuid)
	if err != nil {
		return err
	}

	conn, _, err := websocket.DefaultDialer.Dial(a.Socket, http.Header{"Origin": []string{s.client.PanelURL}})
	if err != nil {
		return err
	}

	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	go func() {
		conn.WriteJSON(payload{event: "auth", args: []string{a.Token}})

		for {
			select {
			case <-s.cancel:
				conn.WriteMessage(websocket.CloseNormalClosure, nil)
				_ = conn.Close()
				return
			case <-ticker.C:
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
		}
	}()

	return nil
}
