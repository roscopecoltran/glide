package action

import (
	"os"

	"github.com/roscopecoltran/glide/core/cache"
	"github.com/roscopecoltran/glide/core/msg"
)

// CacheClear clears the Glide cache
func CacheClear() {
	l := cache.Location()

	err := os.RemoveAll(l)
	if err != nil {
		msg.Die("Unable to clear the cache: %s", err)
	}

	cache.SetupReset()
	cache.Setup()

	msg.Info("Glide cache has been cleared.")
}
