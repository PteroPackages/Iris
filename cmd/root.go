package cmd

import (
	"net/http"

	"github.com/pteropackages/iris/router"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use: "iris",
	Run: func(cmd *cobra.Command, args []string) {
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
