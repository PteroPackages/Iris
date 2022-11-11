package shard

import (
	"bytes"
	"os"
	"path/filepath"

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

	s := &Shard{
		manager: m,
		cancel:  m.cancel,
		uuid:    uuid,
		path:    path,
		data:    &bytes.Buffer{},
		log:     &bytes.Buffer{},
	}
	m.shards = append(m.shards, s)

	return nil
}

func (m *Manager) DestroyAll() {
	m.cancel <- struct{}{}
}
