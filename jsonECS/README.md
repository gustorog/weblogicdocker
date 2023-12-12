# Create Task definition and service on ECS

Modify the taskdefinition.json and run command:
`aws ecs register-task-definition --cli-input-json file://task-definition-weblogic.json`

Modify the ecs-service.json with the necessary values and resources and run command:
`aws ecs create-service --cli-input-json file://ecs-service-configuration.json`



