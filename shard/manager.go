package shard

import (
	"os"
	"path/filepath"
	"time"

	croc "github.com/parkervcp/crocgodyl"
)

type Manager struct {
	client *croc.Client
	shards []*Shard
	cancel chan struct{}
}

func NewManager(url, key string) *Manager {
	client, _ := croc.NewClient(url, key)

	return &Manager{
		client: client,
		shards: []*Shard{},
		cancel: make(chan struct{}),
	}
}

func (m *Manager) Count() int {
	return len(m.shards)
}

func (m *Manager) All() []*Shard {
	return m.shards
}

func (m *Manager) CreateShard(uuid, path string) error {
	path = filepath.Join(path, uuid)

	if err := os.MkdirAll(path, os.ModeDir); err != nil {
		return err
	}

	fd, err := os.Create(filepath.Join(path, time.Now().Format("02-06-2006-150405.data")))
	if err != nil {
		return err
	}

	fl, err := os.Create(filepath.Join(path, time.Now().Format("02-06-2006-150405.log")))
	if err != nil {
		return err
	}

	s := &Shard{
		client: m.client,
		cancel: m.cancel,
		uuid:   uuid,
		data:   fd,
		log:    fl,
	}
	m.shards = append(m.shards, s)

	return nil
}

func (m *Manager) Destroy() {
	m.cancel <- struct{}{}
	close(m.cancel)
}
