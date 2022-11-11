package shard

import (
	"bytes"
	"fmt"
	"time"

	"github.com/gorilla/websocket"
)

type Shard struct {
	manager *Manager
	cancel  chan struct{}
	uuid    string
	path    string
	data    *bytes.Buffer
	log     *bytes.Buffer
}

func (s *Shard) UUID() string {
	return s.uuid
}

func (s *Shard) Launch() error {
	a, err := s.manager.client.GetServerWebSocket(s.uuid)
	if err != nil {
		return err
	}

	conn, _, err := websocket.DefaultDialer.Dial(a.Socket, nil)
	if err != nil {
		return err
	}

	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	go func() {
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
