# Description:
#  Fluxctl commands
apiToken  = process.env.HUBOT_TRAVIS_ACCESS_TOKEN ? null
allowed_users = process.env.HUBOT_ALLOWED_USERS ? null
allowed_users = allowed_users.split ","

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
      Manual: https://builders.travis-ci.com/engineering/runbooks/fluxbot/"""


  robot.respond /deploy (.*) @ (.*) as (.*) on (.*)$/i, (msg) ->
    @exec = require('child_process').exec
    app = msg.match[1]
    commit = msg.match[2]
    deployment_name = msg.match[3]
    project = msg.match[4]
    user = msg.message.user.name
    
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

    if project == "production" and user not in allowed_users
          msg.send ":no_entry: You are not allowed to deploy on production! :no_entry:"
    else
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
