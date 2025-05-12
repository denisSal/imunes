proc API_restartNode { node_id } {
	if { $node_id == "" } {
		return
	}

	trigger_nodeRecreate $node_id

	undeployCfg
	deployCfg
}

proc API_startNode { node_id } {
	if { $node_id == "" } {
		return
	}

	if { [getFromRunning ${node_id}_running] == true } {
		return
	}

	trigger_nodeCreate $node_id

	undeployCfg
	deployCfg
}

proc API_stopNode { node_id } {
	if { $node_id == "" } {
		return
	}

	if { [getFromRunning ${node_id}_running] != true } {
		return
	}

	trigger_nodeDestroy $node_id

	undeployCfg
	deployCfg
}
