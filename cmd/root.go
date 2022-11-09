package cmd

import (
	"time"

	"github.com/go-playground/validator/v10"
	croc "github.com/parkervcp/crocgodyl"
	"github.com/pteropackages/iris/config"
	"github.com/pteropackages/iris/shard"
	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use: "iris",
	Run: func(cmd *cobra.Command, args []string) {
		log := logrus.New()
		log.SetFormatter(&IrisFormatter{
			DisableColors: false,
		})

		cfg, err := config.Get()
		if err != nil {
			if errs, ok := err.(validator.ValidationErrors); ok {
				log.Error("failed to validate configuration")

				for _, e := range errs {
					log.WithField("field", e.Namespace()).Error("validation for field failed")
				}

				return
			} else {
				log.WithError(err).Fatal("failed to validate configuration")
			}
		}

		app, _ := croc.NewApp(cfg.Panel.URL, cfg.Panel.Key)
		app.Http.Timeout = time.Duration(time.Second * 15)

		// crocgodyl doesn't support cycling paginations yet, so this is all we can do for now
		servers, err := app.GetServers()
		if err != nil {
			log.WithError(err).Fatalf("failed to get panel servers")
		}

		manager := shard.NewManager(cfg.Panel.URL, cfg.Panel.Key)

		for _, s := range servers {
			if !contains(s.Node, cfg.Panel.Nodes) {
				log.WithField("uuid", s.UUID).Info("server not in tracked nodes, skipping")
				continue
			}

			log.WithField("uuid", s.UUID).Info("creating shard")
			if err = manager.CreateShard(s.UUID, cfg.DataDirectory); err != nil {
				log.WithField("uuid", s.UUID).WithError(err).Warn("failed to create shard")
			}
		}

		if manager.Count() == 0 {
			log.Fatal("failed to create any shards, aborting")
		}

		log.Infof("created %d shards, starting launch", manager.Count())
	},
}

func contains(x int, y []int) bool {
	for _, i := range y {
		if x == i {
			return true
		}
	}

	return false
}

func Execute() {
	_ = rootCmd.Execute()
}
