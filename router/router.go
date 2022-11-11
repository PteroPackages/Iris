package router

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func Setup() *gin.Engine {
	router := gin.New()
	router.Use(gin.Recovery())

	// TODO: add router handlers

	router.GET("/", getInformation)

	return router
}

func getInformation(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, gin.H{"version": "0.0.1"})
}
