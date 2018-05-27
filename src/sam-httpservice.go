package dii2p

import (
	"bufio"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/eyedeekay/gosam"
)

type samHTTPService struct {
	subCache []SamURL
	err      error
	c        bool

	samBridgeClient *goSam.Client
	samAddrString   string
	samPortString   string

	transport *http.Transport
	subClient *http.Client

	host      string
	directory string

	servPath string
	servPipe *os.File
	servScan *bufio.Scanner

	namePath string
	nameFile *os.File
	name     string

	idPath string
	idFile *os.File
	id     int32

	base64Path string
	base64File *os.File
	base64     string
}

func (samService *samHTTPService) initPipes() {
	checkFolder(filepath.Join(connectionDirectory, samService.host))

	samService.servPath, samService.servPipe, samService.err = setupFiFo(filepath.Join(connectionDirectory, samService.host), "send")
	if samService.c, samService.err = Fatal(samService.err, "Pipe setup error", "Pipe setup"); samService.c {
		samService.servScan, samService.err = setupScanner(filepath.Join(connectionDirectory, samService.host), "send", samService.servPipe)
		if samService.c, samService.err = Fatal(samService.err, "Scanner setup Error:", "Scanner set up successfully."); !samService.c {
			samService.cleanupService()
		}
	}

	samService.namePath, samService.nameFile, samService.err = setupFiFo(filepath.Join(connectionDirectory, samService.host), "name")
	if samService.c, samService.err = Fatal(samService.err, "Pipe setup error", "Pipe setup"); samService.c {
		samService.nameFile.WriteString("")
	}

}

func (samService *samHTTPService) sendContent(index string) (*http.Response, error) {
	/*r, dir := samService.getURL(index)
	Log("Getting resource", index)
	resp, err := samService.subClient.Get(r)
	Warn(err, "Response Error", "Getting Response")
	Log("Pumping result to top of parent pipe")
	samService.copyRequest(resp, dir)
	return resp, err*/
	return nil, nil
}

func (samService *samHTTPService) serviceCheck(alias string) bool {
	return false
}

func (samService *samHTTPService) scannerText() (string, error) {
	text := ""
	var err error
	for _, url := range samService.subCache {
		text, err = url.scannerText()
		if len(text) > 0 {
			break
		}
	}
	return text, err
}

func (samService *samHTTPService) hostSet(alias string) (string, string) {
	return "", ""
}

func (samService *samHTTPService) checkName() bool {
	return false
}

func (samService *samHTTPService) writeName(request string) {
	if samService.checkName() {
		samService.host, samService.directory = samService.hostSet(request)
		Log("Setting hostname:", samService.host)
		Log("Looking up hostname:", samService.host)
		samService.name, samService.err = samService.samBridgeClient.Lookup(samService.host)
		samService.nameFile.WriteString(samService.name)
		Log("Caching base64 address of:", samService.host+" "+samService.name)
		samService.id, samService.base64, samService.err = samService.samBridgeClient.CreateStreamSession("")
		samService.idFile.WriteString(fmt.Sprint(samService.id))
		Warn(samService.err, "Local Base64 Caching error", "Cachine Base64 Address of:", request)
		log.Println("Tunnel id: ", samService.id)
		Log("Tunnel dest: ", samService.base64)
		samService.base64File.WriteString(samService.base64)
		Log("New Connection Name: ", samService.base64)
	} else {
		samService.host, samService.directory = samService.hostSet(request)
		Log("Setting hostname:", samService.host)
		samService.initPipes()
		Log("Looking up hostname:", samService.host)
		samService.name, samService.err = samService.samBridgeClient.Lookup(samService.host)
		Log("Caching base64 address of:", samService.host+" "+samService.name)
		samService.nameFile.WriteString(samService.name)
		samService.id, samService.base64, samService.err = samService.samBridgeClient.CreateStreamSession("")
		samService.idFile.WriteString(fmt.Sprint(samService.id))
		Warn(samService.err, "Local Base64 Caching error", "Cachine Base64 Address of:", request)
		log.Println("Tunnel id: ", samService.id)
		Log("Tunnel dest: ", samService.base64)
		samService.base64File.WriteString(samService.base64)
		Log("New Connection Name: ", samService.base64)
	}
}

func (samService *samHTTPService) printDetails() string {
	s, e := samService.scannerText()
	Fatal(e, "Response Retrieval Error", "Retrieving Responses")
	return s
}

func (samService *samHTTPService) cleanupService() {
	samService.servPipe.Close()
	samService.nameFile.Close()
	for _, url := range samService.subCache {
		url.cleanupDirectory()
	}
	err := samService.samBridgeClient.Close()
	Fatal(err, "SAM Service Connection Closing Error", "Closing SAM service Connection")
	os.RemoveAll(filepath.Join(connectionDirectory, samService.host))
}

func createSamHTTPService(samAddr string, samPort string, alias string) samHTTPService {
	var samService samHTTPService
	return samService
}
