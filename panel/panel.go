package panel

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/pteropackages/iris/config"
)

type Client struct {
	client *http.Client
	config *config.Config
}

func New(cfg *config.Config) *Client {
	return &Client{
		client: &http.Client{},
		config: cfg,
	}
}

// TODO: replace these functions with crocgodyl methods

func (c *Client) GetNodeInformation(id int) error {
	url := fmt.Sprintf("%s/api/application/nodes/%d/configuration", c.config.Panel.URL, id)
	req, _ := http.NewRequest("GET", url, nil)

	req.Header.Set("Authorization", "Bearer "+c.config.Panel.Key)
	req.Header.Set("Accept", "application/json")

	res, err := c.client.Do(req)
	if err != nil {
		return err
	}

	if res.StatusCode != 200 {
		return fmt.Errorf("received an unexpected status from the panel (code: %d)", res.StatusCode)
	}

	defer res.Body.Close()
	buf, err := io.ReadAll(res.Body)
	if err != nil {
		return err
	}

	var info *config.NodeInformation
	if err = json.Unmarshal(buf, &info); err != nil {
		return err
	}
	info.ID = id

	c.config.Nodes[id] = info

	return nil
}
