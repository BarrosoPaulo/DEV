

pipeline {
    agent {
        label 'docker-host'
    }
    options {
        disableConcurrentBuilds()
        disableResume()
    }

    parameters {
        string name: 'ENVIRONMENT_NAME', trim: true
        choice(name: 'DB_ENGINE', choices: ['Mysql', 'Postgres'], description: 'Select the database engine')
        password defaultValue: '', description: 'Password to use for DB container - root user', name: 'DB_PASSWORD'
        string name: 'DB_PORT', trim: true, description: 'Port range 3000-3999'

        booleanParam(name: 'SKIP_STEP_1', defaultValue: false, description: 'STEP 1 - RE-CREATE DOCKER IMAGE')
    }
  
    stages {
        stage('Validate parameters input'){
          when {
            expression { 
                return params.DB_PORT ==~ /^(?!(3[0-9][0-9][0-9])$).*/
              }
          }
          steps {
            script {
              currentBuild.result = "FAILURE"
              throw new Exception("The port should be under port range 3000-3999")
            }
          }
        }
        stage('Checkout GIT repository') {
            steps {     
              script {
                git branch: 'master',
                credentialsId: '8dc4b91c-9bdb-44cd-83cd-16c4eef9f584',
                url: 'https://github.com/brunoaguiar21/jenkins-worktest.git'
              }
            }
        }
        stage('Create latest Docker image') {
          steps {     
            script {
              if (!params.SKIP_STEP_1){

                if(params.DB_ENGINE == 'Mysql'){
                  echo "Creating docker image with name $params.ENVIRONMENT_NAME using port: $params.DB_PORT"
                  sh """
                  sed 's/<PASSWORD>/$params.DB_PASSWORD/g' pipelines/include/create_developer.template > pipelines/include/create_developer.sql
                  """

                  sh """
                  docker build pipelines/ -t $params.ENVIRONMENT_NAME:latest
                  """
                }

              }else{
                  echo "Skipping STEP1"
              }
            }
            script {
              if (!params.SKIP_STEP_1){
                 if(params.DB_ENGINE == 'Postgres'){
                  echo "Creating docker image with name $params.ENVIRONMENT_NAME using port: $params.DB_PORT"
                
                  sh """
                  docker build . -f pipelines/Dockerfile.postgres -t $params.ENVIRONMENT_NAME:latest
                  """
                 }
              }
            }
          }
        }
        stage('Start new container using latest image and create user') {
            steps {     
              script {
                def dateTime = (sh(script: "date +%Y%m%d%H%M%S", returnStdout: true).trim())
                def containerName = "${params.ENVIRONMENT_NAME}_${dateTime}"
                
                if(params.DB_ENGINE == 'Mysql'){
                  sh """
                  docker run -itd --name ${containerName} --rm -e MYSQL_ROOT_PASSWORD=$params.DB_PASSWORD -p $params.DB_PORT:3306 $params.ENVIRONMENT_NAME:latest
                  """
                  
                  sleep(180) // iterate with container for checking port state

                  sh """
                  docker exec ${containerName} /bin/bash -c 'mysql --user="root" --password="$params.DB_PASSWORD" < /scripts/create_developer.sql'
                  """

                  sh """
                  docker exec ${containerName} /bin/bash -c 'mysql --user="root" --password="$params.DB_PASSWORD" < /scripts/create_table.sql'
                  """

                  echo "Docker container created: $containerName"
                }else if(params.DB_ENGINE == 'Postgres'){
                  sh """
                  docker run -itd --name ${containerName} --rm -e POSTGRES_PASSWORD=$params.DB_PASSWORD -p $params.DB_PORT:5432 $params.ENVIRONMENT_NAME:latest
                  """

                  echo "Docker container created: $containerName"
                }
              }
            }
        }
    }

}
