package main 

import (
	"net/http"
	"github.com/gorilla/mux"
	"github.com/niaragorn7/Ordane/cmd/routes"
)

func main(){
	r := mux.NewRouter()
	r.HandleFunc("/", routes.HomeHandler).Methods("GET")
	http.ListenAndServe(":3000", r)

}