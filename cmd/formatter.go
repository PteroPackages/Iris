package cmd

import (
	"bytes"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

type IrisFormatter struct {
	*logrus.TextFormatter

	DisableColors bool
}

func (f *IrisFormatter) wrapColor(c int, v string) string {
	if f.DisableColors {
		return v
	}

	if _, ok := os.LookupEnv("NO_COLOR"); ok {
		return v
	}

	return fmt.Sprintf("\033[%dm%s\033[0m", c, v)
}

func (f *IrisFormatter) Format(entry *logrus.Entry) ([]byte, error) {
	buf := &bytes.Buffer{}
	buf.WriteString(entry.Time.Format(time.RFC3339) + " ")

	switch entry.Level {
	case logrus.TraceLevel:
		buf.WriteString("TRACE")
	case logrus.DebugLevel:
		buf.WriteString("DEBUG")
	case logrus.InfoLevel:
		buf.WriteString(f.wrapColor(36, "INFO"))
	case logrus.WarnLevel:
		buf.WriteString(f.wrapColor(33, "WARN"))
	case logrus.ErrorLevel:
		fallthrough
	case logrus.FatalLevel:
		buf.WriteString(f.wrapColor(31, "ERROR"))
	}

	buf.WriteString(" " + entry.Message)

	for k, v := range entry.Data {
		s := fmt.Sprintf("%v", v)

		if strings.Contains(s, " ") {
			s = fmt.Sprintf("\"%s\"", s)
		}

		buf.WriteString(fmt.Sprintf(" %s=%s", k, s))
	}

	buf.WriteRune('\n')

	return buf.Bytes(), nil
}
