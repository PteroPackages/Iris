package shard

import (
	"os"
	"path/filepath"

	croc "github.com/parkervcp/crocgodyl"
)

type Manager struct {
	client *croc.Client
	shards map[string]*Shard
}

func NewManager(url, key string) *Manager {
	client, _ := croc.NewClient(url, key)

	return &Manager{
		client: client,
		shards: make(map[string]*Shard),
	}
}

func (m *Manager) Count() int {
	return len(m.shards)
}

func (m *Manager) Shard(id string) *Shard {
	return m.shards[id]
}

func (m *Manager) CreateShard(uuid, path string) error {
	path = filepath.Join(path, uuid)

	if _, err := os.Stat(path); err != nil {
		if !os.IsExist(err) {
			return err
		}

		if err = os.MkdirAll(path, os.ModeDir); err != nil {
			return err
		}
	}

	s := &Shard{
		manager: m,
		uuid:    uuid,
		path:    path,
	}
	m.shards[uuid] = s

	return nil
}
