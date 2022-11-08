package cmd

import (
	"github.com/go-playground/validator/v10"
	croc "github.com/parkervcp/crocgodyl"
	"github.com/pteropackages/iris/config"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use: "iris",
	Run: func(cmd *cobra.Command, args []string) {
		cfg, err := config.Get()
		if err != nil {
			if errs, ok := err.(validator.ValidationErrors); ok {
				log.Error("failed to validate configuration")
				for i, e := range errs {
					log.WithFields(log.Fields{
						"key":     e.Param(),
						"message": e.Error(),
					}).Errorf("error #%d", i)
				}

				return
			} else {
				log.WithField("error", err.Error()).Fatal("unexpected error when validating configuration")
			}
		}

		app, _ := croc.NewApp(cfg.Panel.URL, cfg.Panel.Key)
		nodes, err := app.GetNodes()
		if err != nil {
			log.WithError(err).Fatal("failed to fetch nodes from panel")
		}

		for _, n := range nodes {
			c, err := app.GetNodeConfiguration(n.ID)
			if err != nil {
				log.WithField("node", n.ID).WithError(err).Warn("failed to get configuration")
				continue
			}

			cfg.Nodes[n.ID] = c
		}
	},
}

func Execute() {
	_ = rootCmd.Execute()
}
