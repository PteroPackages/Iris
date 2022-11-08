package config

import (
	"io"
	"os"
	"path/filepath"

	_ "github.com/creasty/defaults"
	"github.com/go-playground/validator/v10"
	"gopkg.in/yaml.v3"
)

type Config struct {
	Panel struct {
		URL   string `validate:"required,url" yaml:"url"`
		Key   string `validate:"required,startswith=ptlc_" yaml:"key"`
		Nodes []int  `validate:"required,dive,required,numeric" yaml:"nodes"`
	} `validate:"required" yaml:"panel"`

	DataDirectory string `validate:"dir" yaml:"data_directory"`
	LogDirectory  string `validate:"dir" yaml:"log_directory"`
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
