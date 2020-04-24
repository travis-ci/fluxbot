# Description:
#  Fluxctl commands
apiToken  = process.env.HUBOT_TRAVIS_ACCESS_TOKEN ? null

module.exports = (robot) ->

  robot.router.post "/hubot/:project/:repo/:app/:commit/:status", (request, response) ->
    payload = request.body
    build_url = JSON.stringify(payload.build_url)

    color = "00cc66"
    build_status = "successful"
    if request.params.status != "success"
      color = "#ff0000"
      build_status = "failed"
    msg = {
      attachments: [
        title: "#{build_status}"
        color: "#{color}"
        text: "deployment of #{request.params.repo}/#{request.params.app} @ #{request.params.commit} on #{request.params.project} #{build_status} \n #{build_url}"
      ]
    }

    robot.messageRoom("C03J1T613", msg)
    response.send 'OK'

  robot.respond /help$/i, (msg) ->
    msg.send """Deploy app to k8s: fluxbot deploy <repo slug> @ <commit SHA or branch name> as <k8s deployment name> on <staging or production> \n
      List deployments: fluxbot list deployments on <staging/production> <com/org>
      Describe deployment: fluxbot describe <app> on <staging/production>
      Manual: https://builders.travis-ci.com/engineering/runbooks/fluxbot/"""

   robot.respond /list deployments on (.*) (.*)$/i, (msg) ->
    @exec = require('child_process').exec
    ns = msg.match[1]
    domain = msg.match[2]
    if ns in ['staging']
      if domain in ['org']
        ns = "-n gce-staging-services-1"
      else if domain in ['com']
        ns = "-n gce-staging-pro-services-1"
      else 
        msg.send "Please provide correct domain com/org"
      context = "gke_travis-ci-staging-services-1_us-east4_travis-ci-services-1"
    else if ns in ['prod'] || ns in ['production']
      if domain in ['org']
        ns = "-n gce-production-services-1"
      else if domain in ['com']
        ns = "-n gce-production-pro-services-1"
      else 
        msg.send "Please provide correct domain com/org"
      context = "gke_travis-ci-prod-services-1_us-east1_travis-ci-services"
    else
      msg.send "Please provide environment: staging or production"
    cmd = "kubectl config use-context #{context} && kubectl #{ns} get deployment -o=custom-columns=NAME:.metadata.name,IMAGE:..containers..image"
    msg.send "kubectl #{ns} get deployments"
    @exec cmd, (error, stdout, stderr) ->
      if error
        msg.send error
        msg.send stderr
      else
        msg.send stdout

   robot.respond /describe (.*) on (.*)$/i, (msg) ->
    @exec = require('child_process').exec
    app = msg.match[1]
    ns = msg.match[2]
    if ns in ['staging']
      if /pro/.test "#{app}"  
        ns = "-n gce-staging-pro-services-1"
      else 
        ns = "-n gce-staging-services-1"
      context = "gke_travis-ci-staging-services-1_us-east4_travis-ci-services-1"
    else if ns in ['prod'] || ns in ['production']
      if /pro/.test "#{app}"  
        ns = "-n gce-production-pro-services-1"
      else 
        ns = "-n gce-production-services-1"
      context = "gke_travis-ci-prod-services-1_us-east1_travis-ci-services"
    else
      msg.send "Please provide environment: staging or production"
    cmd = "kubectl config use-context #{context} && kubectl #{ns} describe deployment #{app}"
    msg.send "kubectl #{ns} describe #{app}"
    @exec cmd, (error, stdout, stderr) ->
      if error
        msg.send error
        msg.send stderr
      else
        msg.send stdout
 

  robot.respond /deploy (.*) @ (.*) as (.*) on (.*)$/i, (msg) ->
    @exec = require('child_process').exec
    app = msg.match[1]
    commit = msg.match[2]
    deployment_name = msg.match[3]
    project = msg.match[4]

    requestBody =
      request: {
        message: "#{app} @ #{commit} as #{deployment_name} on #{project}",
        config: {
          merge_mode: "deep_merge_append",
          env: {
            PROJECT: "#{project}"
            K8S_APP_REPO: "#{app}"
            K8S_APP_REPO_COMMIT: "#{commit}"
            DEPLOYMENT_NAME: "#{deployment_name}"
            CLOUDSDK_CORE_DISABLE_PROMPTS: "1"
          }
        }
      }

    data = JSON.stringify(requestBody)

    robot.http("https://api.travis-ci.com/repo/travis-infrastructure%2Fk8s-deploy/requests")
      .header('Content-Type', 'application/json')
      .header('Accept', 'application/json')
      .header('Travis-API-Version', 3)
      .header('Authorization', "token #{apiToken}")
      .post(data) (err, response, body) ->
        if err
          msg.send err
        else
          msg.send
            channel: "C03J1T613" 
            attachments: [
              title: "Status"
              color: "#ffcc66"
              text: "#{msg.message.user.name}'s deployment of #{app} @ #{commit} as #{deployment_name} on #{project} is running :ship_it_parrot:"
            ]
