//Whether Tome should run or not 
#macro TOME_ENABLED true

// Personal access token obtained from github.com/settings/tokens
#macro TOME_GITHUB_AUTH_TOKEN ""

// Your Github username
#macro TOME_GITHUB_USERNAME "username"

// The name of the repo where the generated docs will be commited and pushed
#macro TOME_GITHUB_REPO_NAME "repoName"

// The branch of the repo where the generated docs will be pushed
#macro TOME_GITHUB_REPO_BRANCH "main"

//The directory within your Github repo where your docs will be pushed (In the case you don't want your doc folder at the root of your repo) 
#macro TOME_GITHUB_REPO_DOC_DIRECTORY "" // This is the root by default (""). When specifying a directory, always append a "/" at the end like: "myDirectory/"

// Show extended debug information in the console 
#macro TOME_VERBOSE true

// Use an external text file to store your Github token (useful if pushing to a public repo)
#macro TOME_USE_EXTERNAL_TOKEN false

#macro TOME_EXTERNAL_TOKEN_PATH ""

// Instead of pushing files directly to Github, instead copy them to a local directory to be pushed manually 
#macro TOME_LOCAL_REPO_MODE false

#macro TOME_LOCAL_REPO_PATH ""

