package main

import (
	"fmt"
	"os"
	"log"

	"github.com/jszwedko/go-circleci"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/iam"
)

type config struct {
	circleToken 	string
	circleOrg		string
	circleProject	string
	awsUser			string
}

func main() {
	
	c := config {
		circleToken: os.Getenv("CIRCLE_TOKEN"),
		circleOrg: os.Getenv("CIRCLE_ORG"),
		circleProject: os.Getenv("CIRCLE_PROJECT"),
		awsUser: os.Getenv("AWS_USER"),
	}

	// create iam client
	iamClient := iam.New(session.New())

	// create circleci client
	circleci := &circleci.Client{Token: c.circleToken}

	// valdate the user actually exists
	_, err := iamClient.GetUser(
		&iam.GetUserInput{
			UserName: aws.String(c.awsUser),
		},
	)
	if err != nil {
		log.Fatal("Error finding aws user")
	}

	// get list of aws keys for the user
	accessKeys, err := iamClient.ListAccessKeys(
		&iam.ListAccessKeysInput{
			UserName: aws.String(c.awsUser),
		},
	)

	
	// generate a new key pair
	newKeys, err := iamClient.CreateAccessKey(
		&iam.CreateAccessKeyInput{
			UserName: aws.String(c.awsUser),
		},
	)
	if err != nil {
		log.Fatal(err)
	}

	// // list env vars for the circleci project
	// environmentVariables, err := circleci.ListEnvVars(c.circleOrg,c.circleProject)
	// if err != nil {
	// 	log.Fatal("Error fetching environment variables")
	// }

	// for _, envVar := range environmentVariables {
	// 	fmt.Println(envVar)
	// }

	// delete access and secret key so they can be added back
	err = circleci.DeleteEnvVar(c.circleOrg,c.circleProject,"AWS_ACCESS_KEY_ID")
	if err != nil {
		log.Fatal(err)
	}
	err = circleci.DeleteEnvVar(c.circleOrg,c.circleProject,"AWS_SECRET_ACCESS_KEY")
	if err != nil {
		log.Fatal(err)
	}

	// add back access and secret key from newly generated keys
	_, err = circleci.AddEnvVar(c.circleOrg,c.circleProject,"AWS_ACCESS_KEY_ID", *newKeys.AccessKey.AccessKeyId)
	if err != nil {
		log.Fatal("Error creating env variable")
	}
	_, err = circleci.AddEnvVar(c.circleOrg,c.circleProject,"AWS_SECRET_ACCESS_KEY", *newKeys.AccessKey.SecretAccessKey)
	if err != nil {
		log.Fatal("Error creating env variable")
	}

	// cleanup old keys (should only be one key)
	for _, key := range accessKeys.AccessKeyMetadata {
	
		_, err := iamClient.DeleteAccessKey(
			&iam.DeleteAccessKeyInput{
				AccessKeyId: aws.String(*key.AccessKeyId),
				UserName:    aws.String(c.awsUser),
			},
		)
		if err != nil {
			log.Fatal(err)
		}
	}
	fmt.Println("Keys rotated...")
}

