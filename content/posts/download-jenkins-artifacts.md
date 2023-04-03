---
title: "Downloading Jenkins Artifacts via the CLI"
date: 2023-04-02T18:28:29+02:00
tags: ["Jenkins", "CLI", "wget","curl"]
---

## Problem

I recently needed to download an artifact from a Jenkins build to my remote dev machine.
The remote machine has access to the Jenkins controller, so I just ran `wget` with the link.

```bash
$ wget https://jenkins.local/job/.../artifact/my_artifact.tar.gz
```

I got this back:

```bash
HTTP request sent, awaiting response... 403 Forbidden
2023-04-02 17:43:27 ERROR 403: Forbidden.
```

Jenkins required authentication...

## Solution

### API Token

To authenticate ourselves we need to supply username and an *API token*.
The token can be generated in the Web-UI:

1. Click on your username in the top right corner
2. Click *"Configure"* in the side menu
3. Under the API Token section, click *"Add new Token"*, give it a name and click *"Generate"*

It should look something like this: `11a6b656cac594240285968eaa9347f491`

### Wget

Now we can provide this information to `wget` and download our file.

```bash
$ wget --auth-no-challenge --user=david --password=11a6b656cac594240285968eaa9347f491 https://...
```

Now it works! But, it's not really recommended to pass API tokens on the command line since the secret can be easily
exposed that way, so let's put it in a file.

### Security and usability improvements

By having the username and API token as environment variables we can refer to them in the CLI
instead of writing them out in plain text.

```bash
# ~/.jenkins_token
JENKINS_USERNAME=david
JENKINS_TOKEN=11a6b656cac594240285968eaa9347f491
```

Change the file permissions so only your user can view the file contents:

```bash
$ chmod 600 ~/jenkins_token
```

To access these environment variables, we need to source the file.
Put this in your `~/.zshenv` or `~/.bashrc` depending on what shell you use.

```bash
# ~/.zshenv or ~/.bashrc
source $HOME/.jenkins_token
```

Now if we open up a fresh terminal we can access them like this:

```bash
$ wget --auth-no-challenge --user=$JENKINS_USERNAME --password=$JENKINS_TOKEN
```

### Utility functions

To make it easier to use, we can create a utility function.
Here we also add support for authenticated `curl`.

```bash
# ~/.zshrc or ~/.bashrc
wget_jenkins() {
    wget --auth-no-challenge --user=$JENKINS_USERNAME --password=$JENKINS_TOKEN $@
}

curl_jenkins() {
    curl --user ${JENKINS_USERNAME}:${JENKINS_TOKEN} $@
}
```

Now it's much easier to download files!

```bash
$ wget_jenkins https://...
# or
$ curl_jenkins -o artifact.tar.gz https://...
```

### Bonus: Trigger jobs

In addition to downloading artifacts, you can also use the `curl_jenkins` function to trigger Jenkins jobs remotely:

```bash
$ curl_jenkins -X POST -L https://jenkins.local/job/your_job/build
```

## Conclusion

In conclusion, this article provides a practical solution for downloading
artifacts and triggering Jenkins jobs remotely using the `wget` and `curl` tools.

### Official documentation

[Jenkins - Authenticating scripted clients](https://www.jenkins.io/doc/book/system-administration/authenticating-scripted-clients/)
