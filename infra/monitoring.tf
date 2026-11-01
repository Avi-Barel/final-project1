resource "aws_sns_topic" "alerts" {
  name = "${local.name}-alerts"

  tags = {
    Name = "${local.name}-alerts"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${local.name}-alb-5xx"
  }
}
