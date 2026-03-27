import boto3

# Initialize CloudWatch and SNS clients
cloudwatch = boto3.client('cloudwatch')
sns = boto3.client('sns')

# Create SNS topic for alarm notifications
def create_sns_topic():
    """Create SNS topic for CloudWatch alarm notifications"""
    response = sns.create_topic(Name='LinguaLearn-Alerts')
    topic_arn = response['TopicArn']

    # Subscribe email to topic
    sns.subscribe(
        TopicArn=topic_arn,
        Protocol='email',
        Endpoint='your-email@example.com'  # Update with your email
    )

    print(f"SNS topic created: {topic_arn}")
    return topic_arn

# Create CloudWatch alarms for critical metrics
def create_alarms(sns_topic_arn):
    """
    Create CloudWatch alarms:
    - High CPU usage on RDS
    - High API error rate
    - RDS connection pool exhaustion
    - Lambda errors
    """

    # Alarm 1: RDS CPU > 70% for 5 minutes
    cloudwatch.put_metric_alarm(
        AlarmName='LinguaLearn-RDS-HighCPU',
        ComparisonOperator='GreaterThanThreshold',
        EvaluationPeriods=1,
        MetricName='CPUUtilization',
        Namespace='AWS/RDS',
        Period=300,
        Statistic='Average',
        Threshold=70.0,
        ActionsEnabled=True,
        AlarmActions=[sns_topic_arn],
        AlarmDescription='Alert when RDS CPU exceeds 70%',
        Dimensions=[
            {
                'Name': 'DBInstanceIdentifier',
                'Value': 'linguallearn-db-dev'
            }
        ]
    )

    # Alarm 2: API Error Rate > 1%
    cloudwatch.put_metric_alarm(
        AlarmName='LinguaLearn-API-HighErrorRate',
        ComparisonOperator='GreaterThanThreshold',
        EvaluationPeriods=2,
        Metrics=[
            {
                'Id': 'error_rate',
                'Expression': '(m2 / m1) * 100',
                'Label': 'Error Rate %'
            },
            {
                'Id': 'm1',
                'MetricStat': {
                    'Metric': {
                        'Namespace': 'AWS/ApplicationELB',
                        'MetricName': 'RequestCount'
                    },
                    'Period': 300,
                    'Stat': 'Sum'
                },
                'ReturnData': False
            },
            {
                'Id': 'm2',
                'MetricStat': {
                    'Metric': {
                        'Namespace': 'AWS/ApplicationELB',
                        'MetricName': 'HTTPCode_Target_5XX_Count'
                    },
                    'Period': 300,
                    'Stat': 'Sum'
                },
                'ReturnData': False
            }
        ],
        Threshold=1.0,
        ActionsEnabled=True,
        AlarmActions=[sns_topic_arn],
        AlarmDescription='Alert when API error rate exceeds 1%'
    )

    # Alarm 3: RDS Connections > 80% of max
    cloudwatch.put_metric_alarm(
        AlarmName='LinguaLearn-RDS-HighConnections',
        ComparisonOperator='GreaterThanThreshold',
        EvaluationPeriods=1,
        MetricName='DatabaseConnections',
        Namespace='AWS/RDS',
        Period=300,
        Statistic='Average',
        Threshold=80.0,
        ActionsEnabled=True,
        AlarmActions=[sns_topic_arn],
        AlarmDescription='Alert when RDS connections exceed 80',
        Dimensions=[
            {
                'Name': 'DBInstanceIdentifier',
                'Value': 'linguallearn-db-dev'
            }
        ]
    )

    # Alarm 4: Lambda Errors > 5 in 10 minutes
    cloudwatch.put_metric_alarm(
        AlarmName='LinguaLearn-Lambda-HighErrors',
        ComparisonOperator='GreaterThanThreshold',
        EvaluationPeriods=1,
        MetricName='Errors',
        Namespace='AWS/Lambda',
        Period=600,
        Statistic='Sum',
        Threshold=5.0,
        ActionsEnabled=True,
        AlarmActions=[sns_topic_arn],
        AlarmDescription='Alert when Lambda errors exceed 5 in 10 minutes',
        Dimensions=[
            {
                'Name': 'FunctionName',
                'Value': 'linguallearn-ml-inference-dev'
            }
        ]
    )

    print("✅ All CloudWatch alarms created successfully!")

# Main execution
if __name__ == "__main__":
    topic_arn = create_sns_topic()
    create_alarms(topic_arn)
    print("✅ Monitoring setup complete!")
