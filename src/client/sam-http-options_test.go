package dii2pmain

import (
	"net/http"
	"testing"
)

func (addressBook *AddressHelper) request() *http.Request {
	u, e := url.Parse("i2p-projekt.i2p")
	if e != nil {
		return req
	}
	body := ""
	contentLength := int64(len(body))
	return &http.Request{
		URL:              u,
		Body:             ioutil.NopCloser(strings.NewReader(string(body))),
		ContentLength:    contentLength,
		RequestURI:       "",
	}
}

func TestCreateSamHTTPOptionsAll(t *testing.T) {
	length := 1
	quant := 15
	timeout := 600
	lifeout := 1200
	backup := 3
	idles := 4
	var req *http.Request
    req = http.Request{}
	newSamHTTPHTTP("127.0.0.1",
		"7656",
		req,
		timeout,
		lifeout,
		true,
		length,
		quant,
		quant,
		idles,
		backup,
		backup)
}
