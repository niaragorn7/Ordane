package main
import (
	"fmt"
	"net/http"
)

func homeHandler(w http.ResponseWriter, r *http.Request){
	fmt.Fprintf(w, "Helloooooooo")
}

func  aboutHandler(w http.ResponseWriter, r *http.Request){
	fmt.Fprintf(w, "about DicoPatito")
}

func main() {
	http.HandleFunc("/", homeHandler)
	http.HandleFunc("/about", aboutHandler)
    http.ListenAndServe(":8080", nil)
}