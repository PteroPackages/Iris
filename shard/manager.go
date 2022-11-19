package shard

import (
	"bytes"
	"os"
	"path/filepath"
	"time"

	croc "github.com/parkervcp/crocgodyl"
	"github.com/sirupsen/logrus"
)

type Manager struct {
	client *croc.Client
	log    *logrus.Logger
	shards []*Shard
	cancel chan struct{}
}

func NewManager(url, key string, log *logrus.Logger) *Manager {
	client, _ := croc.NewClient(url, key)

	return &Manager{
		client: client,
		log:    log,
		shards: []*Shard{},
		cancel: make(chan struct{}),
	}
}

func (m *Manager) Count() int {
	return len(m.shards)
}

func (m *Manager) Shards() []*Shard {
	return m.shards
}

func (m *Manager) Create(uuid, path string) {
	path = filepath.Join(path, uuid)
	m.log.Debugf("manager: %s", path)

	if err := os.MkdirAll(path, os.ModeDir); err != nil {
		m.log.WithError(err).Error("failed to create directory")
		return
	}

	t := time.Now()
	s := &Shard{
		client: m.client,
		cancel: m.cancel,
		log:    m.log,
		uuid:   uuid,
		path:   filepath.Join(path, t.Format("02-06-2006-150405.data")),
		data:   &bytes.Buffer{},
	}
	m.shards = append(m.shards, s)
}

func (m *Manager) Destroy() {
	m.cancel <- struct{}{}
	close(m.cancel)
}
