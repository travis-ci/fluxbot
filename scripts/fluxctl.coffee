# Description:
#  Fluxctl commands

module.exports = (robot) ->

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

  robot.respond /release (.*) on (.*)$/i, (msg) ->
    @exec = require('child_process').exec
    ns = msg.match[1]
    ns = msg.match[2]
    if ns in ['gce-staging-1']
      ns = "-n #{ns}"
    else
      msg.send "release on #{ns} namespace on allowed"
    cmd = "fluxctl --k8s-fwd-ns=flux list-workloads #{ns}"
    msg.send "Running [#{cmd}]..."

    @exec cmd, (error, stdout, stderr) ->
      if error
        msg.send error
        msg.send stderr
      else
        msg.send stdout
