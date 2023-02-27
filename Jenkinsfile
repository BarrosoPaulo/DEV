def validPort(value){
  return value < 3000 && value > 4000
}

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
        password defaultValue: '', description: 'Password to use for MySQL container - root user', name: 'MYSQL_PASSWORD'
        string name: 'MYSQL_PORT', trim: true, description: 'Port range 3000-3999'

        booleanParam(name: 'SKIP_STEP_1', defaultValue: false, description: 'STEP 1 - RE-CREATE DOCKER IMAGE')
    }
  
    stages {
        stage('Port range'){
          when {
            expression { 
                return params.MYSQL_PORT ==~ /^(?!(3[0-9][0-9][0-9])$).*/
              }
          }
          steps {
            script {
              currentBuild.result = "FAILURE"
              throw new Exception("The port should be under port range 3000-4999")
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
                  echo "Creating docker image with name $params.ENVIRONMENT_NAME using port: $params.MYSQL_PORT"
                  sh """
                  sed 's/<PASSWORD>/$params.MYSQL_PASSWORD/g' pipelines/include/create_developer.template > pipelines/include/create_developer.sql
                  """

                  sh """
                  docker build pipelines/ -t $params.ENVIRONMENT_NAME:latest
                  """
                }

              }else{
                  echo "Skipping STEP1"
              }
            }
          }
        }
        stage('Create latest Docker portgres image'){
          when {
            expression {
              params.DB_ENGINE == 'Postgres'
            }
          }
          steps {
            script {
              if (!params.SKIP_STEP_1){
                echo "Creating docker image with name $params.ENVIRONMENT_NAME using port: $params.MYSQL_PORT"
                
                sh """
                docker build . -f pipelines/Dockerfile.postgres -t $params.ENVIRONMENT_NAME:latest
                """
              }
            }
          }
        }
        stage('Start new container using latest image and create user') {
            steps {     
              script {
                if(params.DB_ENGINE == 'Mysql'){
                  def dateTime = (sh(script: "date +%Y%m%d%H%M%S", returnStdout: true).trim())
                  def containerName = "${params.ENVIRONMENT_NAME}_${dateTime}"
                                    
                  sh """
                  docker run -itd --name ${containerName} --rm -e MYSQL_ROOT_PASSWORD=$params.MYSQL_PASSWORD -p $params.MYSQL_PORT:3306 $params.ENVIRONMENT_NAME:latest
                  """
                  
                  sleep(180) // iterate with container for checking port state

                  sh """
                  docker exec ${containerName} /bin/bash -c 'mysql --user="root" --password="$params.MYSQL_PASSWORD" < /scripts/create_developer.sql'
                  """

                  echo "Docker container created: $containerName"
                }
              }
            }
        }
        stage('Start new Postgres container'){
          when {
            expression {
              params.DB_ENGINE == 'Postgres'
            }
          }
          steps {
            script {
              def dateTime = (sh(script: "date +%Y%m%d%H%M%S", returnStdout: true).trim())
              def containerName = "${params.ENVIRONMENT_NAME}_${dateTime}"

              sh """
              docker run -itd --name ${containerName} --rm -e POSTGRES_PASSWORD=$params.MYSQL_PASSWORD -p $params.MYSQL_PORT:5432 $params.ENVIRONMENT_NAME:latest
              """

              echo "Docker container created: $containerName"
            }
          }
        }
    }

}
