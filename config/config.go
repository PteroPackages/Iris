package config

import (
	"io"
	"os"
	"path/filepath"

	_ "github.com/creasty/defaults"
	"github.com/go-playground/validator/v10"
	croc "github.com/parkervcp/crocgodyl"
	"gopkg.in/yaml.v3"
)

type Config struct {
	Address string `default:"127.0.0.1" yaml:"address"`
	Port    int64  `default:"5500" yaml:"port"`
	Panel   struct {
		URL string `yaml:"url"`
		Key string `yaml:"key"`
	} `yaml:"panel"`
	Nodes map[int]*croc.NodeConfiguration `default:"{}" yaml:"-"`
}

func Get() (*Config, error) {
	cfg, err := GetStatic()
	if err != nil {
		return nil, err
	}

	validate := validator.New()
	if err = validate.Struct(cfg); err != nil {
		return nil, err
	}

	return cfg, nil
}

func GetStatic() (*Config, error) {
	root, _ := os.Getwd()
	path := filepath.Join(root, "config.yml")
	if _, err := os.Stat(path); err != nil {
		return nil, err
	}

	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	buf, err := io.ReadAll(file)
	if err != nil {
		return nil, err
	}

	var cfg *Config
	if err = yaml.Unmarshal(buf, &cfg); err != nil {
		return nil, err
	}

	return cfg, nil
}
