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

    robot.messageRoom("CRNJ9AV27", msg)
    robot.messageRoom("C03J1T613", msg)
    response.send 'OK'

  robot.respond /help$/i, (msg) ->
    msg.send """Deploy app to k8s: fluxbot deploy <repo slug> @ <commit SHA or branch name> as <k8s deployment name> on <staging or production> \n
      Manual: https://builders.travis-ci.com/engineering/runbooks/fluxbot/"""

  robot.respond /workloads ?(.*)$/i, (msg) ->
    @exec = require('child_process').exec
    ns = msg.match[1]
    if ns in ['gce-staging-1']
      ns = "-n #{ns}"
    else
      ns = "-a"
    cmd = "fluxctl --k8s-fwd-ns=flux list-workloads #{ns}"
    msg.send "Running [#{cmd}]..."

    @exec cmd, (error, stdout, stderr) ->
      if error
        msg.send error
        msg.send stderr
      else
        msg.send 
          attachments: [
            title: "Status"
            content: "#{stdout}"
          ]


  robot.respond /deploy (.*) @ (.*) as (.*) on (.*)$/i, (msg) ->
    @exec = require('child_process').exec
    app = msg.match[1]
    commit = msg.match[2]
    deployment_name = msg.match[3]
    project = msg.match[4]

    requestBody =
      request: {
        config: {
          merge_mode: "deep_merge",
          env: {
            PROJECT: "#{project}"
            K8S_APP_REPO: "#{app}"
            K8S_APP_REPO_COMMIT: "#{commit}"
            DEPLOYMENT_NAME: "#{deployment_name}"
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
            channel: "CRNJ9AV27" 
            attachments: [
              title: "Status"
              color: "#ffcc66"
              text: "#{msg.message.user.name}'s deployment of #{app} @ #{commit} as #{deployment_name} on #{project} is running :ship_it_parrot:"
            ]
          msg.send
            channel: "C03J1T613" 
            attachments: [
              title: "Status"
              color: "#ffcc66"
              text: "#{msg.message.user.name}'s deployment of #{app} @ #{commit} as #{deployment_name} on #{project} is running :ship_it_parrot:"
            ]