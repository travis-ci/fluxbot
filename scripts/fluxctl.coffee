# Description:
#  Fluxctl commands
apiToken  = process.env.HUBOT_TRAVIS_ACCESS_TOKEN ? null

module.exports = (robot) ->

  robot.router.post "/hubot/:project/:repo/:app/:commit", (request, response) ->
    payload = request.body
    robot.respond payload

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
        msg.send stdout

  robot.respond /deploy (.*) @ (.*) on (.*)$/i, (msg) ->
    @exec = require('child_process').exec
    app = msg.match[1]
    commit = msg.match[2]
    project = msg.match[3]

    requestBody = 
      request: {
        config: {
          merge_mode: "deep_merge",
          env: {
            PROJECT: project
            K8S_APP_REPO: app
          }
        }
      }
    
    data = JSON.stringify(requestBody)

    robot.http("https://api.travis-ci.org/repo/r-arek%2Fspeedtest-pub/requests")
      .header('Content-Type', 'application/json')
      .header('Accept', 'application/json')
      .header('Travis-API-Version', 3)
      .header('Authorization', "token #{apiToken}")
      .post(data) (err, response, body) ->
        if err 
          msg.send err
        else
          msg.send 
            attachments: [
              title: "Status"
              color: "#ffcc66"
              text: "#{msg.message.user.name}'s deployment of #{app} @ #{commit} on #{project} is running"
            ]
