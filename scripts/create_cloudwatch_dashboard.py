import boto3
import json

# Initialize CloudWatch client
cloudwatch = boto3.client('cloudwatch')

# Create comprehensive dashboard for LinguaLearn monitoring
def create_dashboard():
    """
    Create CloudWatch dashboard with key metrics:
    - API latency (p50, p95, p99)
    - ALB request count and error rates
    - RDS CPU, memory, connections
    - Lambda duration and error rates
    - CloudFront bandwidth and cache hit ratio
    """

    dashboard_body = {
        "widgets": [
            # API Latency Widget
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/ApplicationELB", "TargetResponseTime",
                         {"stat": "p50", "label": "p50"}],
                        ["...", {"stat": "p95", "label": "p95"}],
                        ["...", {"stat": "p99", "label": "p99"}]
                    ],
                    "period": 300,
                    "stat": "Average",
                    "region": "us-east-1",
                    "title": "API Latency (ms)",
                    "yAxis": {
                        "left": {
                            "min": 0
                        }
                    }
                }
            },

            # ALB Request Count Widget
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/ApplicationELB", "RequestCount",
                         {"stat": "Sum", "label": "Total Requests"}],
                        [".", "HTTPCode_Target_4XX_Count",
                         {"stat": "Sum", "label": "4XX Errors"}],
                        [".", "HTTPCode_Target_5XX_Count",
                         {"stat": "Sum", "label": "5XX Errors"}]
                    ],
                    "period": 300,
                    "stat": "Sum",
                    "region": "us-east-1",
                    "title": "ALB Request Count & Errors"
                }
            },

            # RDS Performance Widget
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/RDS", "CPUUtilization",
                         {"stat": "Average", "label": "CPU %"}],
                        [".", "FreeableMemory",
                         {"stat": "Average", "label": "Free Memory"}],
                        [".", "DatabaseConnections",
                         {"stat": "Average", "label": "Connections"}]
                    ],
                    "period": 300,
                    "stat": "Average",
                    "region": "us-east-1",
                    "title": "RDS Performance"
                }
            },

            # Lambda Performance Widget
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/Lambda", "Duration",
                         {"stat": "Average", "label": "Avg Duration (ms)"}],
                        [".", "Errors",
                         {"stat": "Sum", "label": "Errors"}],
                        [".", "ConcurrentExecutions",
                         {"stat": "Maximum", "label": "Concurrent"}]
                    ],
                    "period": 300,
                    "stat": "Average",
                    "region": "us-east-1",
                    "title": "Lambda Performance"
                }
            },

            # CloudFront Performance Widget
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/CloudFront", "BytesDownloaded",
                         {"stat": "Sum", "label": "Bandwidth"}],
                        [".", "CacheHitRate",
                         {"stat": "Average", "label": "Cache Hit Rate %"}],
                        [".", "Requests",
                         {"stat": "Sum", "label": "Total Requests"}]
                    ],
                    "period": 300,
                    "stat": "Average",
                    "region": "us-east-1",
                    "title": "CloudFront Performance"
                }
            }
        ]
    }

    # Create dashboard
    response = cloudwatch.put_dashboard(
        DashboardName='LinguaLearn-Production-Dashboard',
        DashboardBody=json.dumps(dashboard_body)
    )

    print(f"Dashboard created: {response}")
    return response

if __name__ == "__main__":
    create_dashboard()
    print("✅ CloudWatch dashboard created successfully!")
