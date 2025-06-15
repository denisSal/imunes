def targets = []

properties([
  buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '10'))
])

pipeline {
	agent any

	parameters {
		string(name: 'IMUNES_REPO', defaultValue: 'https://github.com/imunes/imunes.git', description: 'IMUNES Git repository URL')
		string(name: 'IMUNES_BRANCH', defaultValue: 'master', description: 'IMUNES Git branch')
		string(name: 'EXAMPLES_REPO', defaultValue: 'https://github.com/imunes/imunes-examples.git', description: 'IMUNES examples Git repository URL')
		string(name: 'EXAMPLES_BRANCH', defaultValue: 'master', description: 'IMUNES examples Git branch')
		string(name: 'FREEBSD_TESTS', defaultValue: '', description: 'FreeBSD tests')
		string(name: 'FREEBSD_JOBS', defaultValue: '8', description: 'FreeBSD parallel jobs')
		string(name: 'LINUX_TESTS', defaultValue: '', description: 'Linux tests')
		string(name: 'LINUX_JOBS', defaultValue: '4', description: 'Linux parallel jobs')
		choice(name: 'PLATFORM', choices: ['both', 'FreeBSD', 'Linux'], description: 'Target platform(s) to run tests')
	}


	environment {
		ENV_FILE = '/usr/local/etc/jenkins.env'
		TEST_DIR = '/tmp/imunes-examples'
	}

	stages {
		stage('Init') {
			steps {
				script {
					// Override env variable with parameter value
					env.IMUNES_REPO = params.IMUNES_REPO
					env.IMUNES_BRANCH = params.IMUNES_BRANCH
					env.EXAMPLES_REPO = params.EXAMPLES_REPO
					env.EXAMPLES_BRANCH = params.EXAMPLES_BRANCH
					env.FREEBSD_TESTS = params.FREEBSD_TESTS
					env.FREEBSD_JOBS = params.FREEBSD_JOBS
					env.LINUX_TESTS = params.LINUX_TESTS
					env.LINUX_JOBS = params.LINUX_JOBS
				}
			}
		}

		stage('Load Env') {
			steps {
				script {
					def props = [:]
					def filePath = "${env.ENV_FILE}"

					if (!fileExists(filePath)) {
						error("Environment file '${filePath}' not found.")
					}

					def fileContent = readFile(filePath)
					fileContent.split('\n').each { line ->
						line = line.trim()
						if (line && !line.startsWith('#') && line.contains('=')) {
							def (key, value) = line.split('=', 2)
							props[key.trim()] = value.trim()
						}
					}

					props.each { k, v ->
						echo "Overriding env: ${k} = ${v}"
						env."${k}" = v
					}

					env.LINUX_DEFINED = (props.LINUX_USERNAME && props.LINUX_HOST && props.LINUX_PORT) ? 'true' : 'false'
					env.FREEBSD_DEFINED = (props.FREEBSD_USERNAME && props.FREEBSD_HOST && props.FREEBSD_PORT) ? 'true' : 'false'

					if (env.LINUX_DEFINED == 'true') {
						env.LINUX_SSH = "${props.LINUX_USERNAME}@${props.LINUX_HOST}"
						env.LINUX_PORT = props.LINUX_PORT
					}
					if (env.FREEBSD_DEFINED == 'true') {
						env.FREEBSD_SSH = "${props.FREEBSD_USERNAME}@${props.FREEBSD_HOST}"
						env.FREEBSD_PORT = props.FREEBSD_PORT
					}
				}
			}
		}

		stage('Start Tests') {
			steps {
				script {
					def localTargets = []

					if (params.PLATFORM in ['Linux', 'both'] && env.LINUX_DEFINED == 'true') {
						localTargets << [name: 'Linux', ssh: env.LINUX_SSH, port: env.LINUX_PORT]
					} else if (params.PLATFORM in ['Linux', 'both']) {
						echo "⚠️ Linux test config incomplete. Skipping."
					}

					if (params.PLATFORM in ['FreeBSD', 'both'] && env.FREEBSD_DEFINED == 'true') {
						localTargets << [name: 'FreeBSD', ssh: env.FREEBSD_SSH, port: env.FREEBSD_PORT]
					} else if (params.PLATFORM in ['FreeBSD', 'both']) {
						echo "⚠️ FreeBSD test config incomplete. Skipping."
					}

					targets = localTargets  // save to shared script scope

					for (target in targets) {
						def testSet = target.name == 'Linux' ? env.LINUX_TESTS : env.FREEBSD_TESTS
						def jobs = target.name == 'Linux' ? env.LINUX_JOBS : env.FREEBSD_JOBS
						def logFile = "${env.TEST_DIR}/test_output_${target.name}.log"

						echo "🚀 Starting tests on ${target.name} with TESTS='${testSet}'"
						sh """
						ssh -p ${target.port} ${target.ssh} '
						rm -rf /tmp/imunes_ci &&
						git clone --depth 1 --branch ${env.IMUNES_BRANCH} ${env.IMUNES_REPO} /tmp/imunes_ci &&
						cd /tmp/imunes_ci && sudo make install &&
						rm -rf ${env.TEST_DIR} &&
						git clone --depth 1 --branch ${env.EXAMPLES_BRANCH} ${env.EXAMPLES_REPO} ${env.TEST_DIR} &&
						cd ${env.TEST_DIR} &&
						(
							sudo DETAILS=1 LEGACY=1 TESTS="${testSet}" ./testAll.sh -j ${jobs} > ${logFile} 2>&1 < /dev/null &
						)
						'
						"""
					}
				}
			}
		}

		stage('Poll for Test Completion') {
			steps {
				script {
					def failedTargets = []
					def finishedTargets = [:]
					for (target in targets) {
						finishedTargets[target.name] = false
					}

					for (int attempt = 1; attempt <= 30; attempt++) {
						echo "========================== Polling attempt ${attempt}..."

						for (target in targets) {
							if (finishedTargets.containsKey(target.name) && finishedTargets[target.name]) {

								echo "${target.name} tests already finished. Skipping."
								continue
							}

							def testSet = target.name == 'Linux' ? env.LINUX_TESTS : env.FREEBSD_TESTS
							echo "${target.name} --- waiting for tests: ${testSet}..."

							def logFile = "${env.TEST_DIR}/test_output_${target.name}.log"
							def result = sh(
								script: "ssh -p ${target.port} ${target.ssh} 'grep -q \"Finished\" ${logFile}'",
								returnStatus: true
							)

							if (result == 0) {
								echo "${target.name} tests finished ✅"

								def passed = sh(
									script: "ssh -p ${target.port} ${target.ssh} 'grep -q \"OK\" ${logFile}'",
									returnStatus: true
								)

								if (passed == 0) {
									echo "${target.name} tests passed ✅"
								} else {
									echo "=== ${target.name} test log start ==="
									sh "ssh -p ${target.port} ${target.ssh} 'cat ${env.TEST_DIR}/test_output_${target.name}.log'"
									echo "=== ${target.name} test log end ==="
									echo "${target.name} tests failed ❌"
									failedTargets << target.name
								}

								finishedTargets[target.name] = true
							} else {
								echo "${target.name} tests not finished yet."
							}
						}

						if (finishedTargets.values().every { it }) {
							echo "All tests finished."
							break
						}

						sleep time: 30, unit: 'SECONDS'
					}

					if (!finishedTargets.values().every { it }) {
						error "Test polling timed out after 30 attempts ⏱️"
					}

					if (failedTargets.size() > 0) {
						for (failed in failedTargets) {
							def target = targets.find { it.name == failed }
							def remoteLog = "${env.TEST_DIR}/test_output_${failed}.log"
							echo "=== ${failed} test log start ==="
							sh "ssh -p ${target.port} ${target.ssh} 'cat ${remoteLog}'"
							echo "=== ${failed} test log end ==="
						}

						error("One or more tests failed: ${failedTargets.join(', ')} ❌")
					}
				}
			}
		}
	}

	post {
		always {
			script {
				for (target in targets) {
					def name = target.name
					def remoteDir = "${env.TEST_DIR}"
					def archiveName = "imunes-examples-${name}.tar.gz"
					def localTar = "${archiveName}"
					def localLog = "test_output_${name}.log"
					def remoteLog = "${remoteDir}/test_output_${name}.log"

					// Compress the directory remotely
					sh "ssh -p ${target.port} ${target.ssh} 'tar -czf /tmp/${archiveName} -C /tmp imunes-examples'"

					// Download compressed folder
					sh "scp -P ${target.port} ${target.ssh}:/tmp/${archiveName} ${localTar}"

					// Download test log separately
					sh "scp -P ${target.port} ${target.ssh}:${remoteLog} ${localLog}"

					// Optional: clean up remote archive
					sh "ssh -p ${target.port} ${target.ssh} 'rm -f /tmp/${archiveName}'"
				}

				// Archive both sets
				archiveArtifacts artifacts: '*.tar.gz,test_output_*.log', allowEmptyArchive: true
			}
		}
	}
}
