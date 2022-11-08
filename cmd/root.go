package cmd

import (
	"net/http"

	log "github.com/sirupsen/logrus"
	"github.com/go-playground/validator/v10"
	"github.com/pteropackages/iris/config"
	"github.com/pteropackages/iris/panel"
	"github.com/pteropackages/iris/router"
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

		client := panel.New(cfg)
		if err = client.GetNodeInformation()

		server := &http.Server{
			Addr:    "localhost:5500",
			Handler: router.Setup(),
		}

		_ = server.ListenAndServe()
		// if err := server.ListenAndServe(); err != nil {}
	},
}

func Execute() {
	_ = rootCmd.Execute()
}
