build:
	GOOS=linux go build cmd/key-rotator/main.go
	zip function.zip ./main
	rm -f main