package cmd

import (
	"bytes"
	"os"
	"os/signal"
	"path/filepath"
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
	Run: func(cmd *cobra.Command, _ []string) {
		log := logrus.New()
		log.SetFormatter(&IrisFormatter{
			DisableColors: false,
			data:          &bytes.Buffer{},
		})

		if ok, _ := cmd.Flags().GetBool("debug"); ok {
			log.SetLevel(logrus.DebugLevel)
		}

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

		manager := shard.NewManager(cfg.Panel.URL, cfg.Panel.Key, log)

		for _, s := range servers {
			if !contains(s.Node, cfg.Panel.Nodes) {
				log.WithField("uuid", s.UUID).Info("server not in tracked nodes, skipping")
				continue
			}

			log.WithField("uuid", s.UUID).Info("creating shard")
			manager.Create(s.UUID, cfg.DataDirectory)
		}

		if manager.Count() == 0 {
			log.Fatal("failed to create any shards, aborting")
		}

		log.Infof("created %d shards, starting launch", manager.Count())

		sc := make(chan os.Signal, 1)
		signal.Notify(sc, os.Interrupt)
		defer close(sc)

		launched := 0

		for _, s := range manager.Shards() {
			if err = s.Launch(); err != nil {
				log.WithError(err).WithField("uuid", s.UUID()).Warn("failed to launch shard")
				continue
			}

			log.WithField("uuid", s.UUID()).Info("launched shard")
			launched++
		}

		if launched == 0 {
			log.Error("failed to launch any shards, aborting")
			manager.Destroy()
			return
		}
		log.Infof("tracking %d shards", launched)

		<-sc
		log.Warn("received sigint; destroying all shards")
		manager.Destroy()

		log.Info("saving iris logs")
		fd, err := os.Create(filepath.Join(cfg.LogDirectory, time.Now().Format("02-06-2006-150405.log")))
		if err != nil {
			log.WithError(err).Fatal("failed to save iris logs")
		}

		defer fd.Close()
		fd.Write(log.Formatter.(*IrisFormatter).data.Bytes())
	},
}

func init() {
	rootCmd.CompletionOptions.DisableDefaultCmd = true

	rootCmd.Flags().Bool("debug", false, "run in debug mode")
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
	if err := rootCmd.Execute(); err != nil {
		logrus.WithError(err).Fatal("failed to start application")
	}
}
