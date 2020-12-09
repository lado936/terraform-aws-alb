resource "aws_lb_target_group" "main" {
  name        = lookup(var.target_group, "name", null)
  name_prefix = lookup(var.target_group, "name_prefix", null)

  vpc_id      = data.aws_vpc.default.id
  port        = lookup(var.target_group, "backend_port", null)
  protocol    = lookup(var.target_group, "backend_protocol", null) != null ? upper(lookup(var.target_group, "backend_protocol")) : null
  target_type = lookup(var.target_group, "target_type", null)

  deregistration_delay               = lookup(var.target_group, "deregistration_delay", null)
  slow_start                         = lookup(var.target_group, "slow_start", null)
  proxy_protocol_v2                  = lookup(var.target_group, "proxy_protocol_v2", false)
  lambda_multi_value_headers_enabled = lookup(var.target_group, "lambda_multi_value_headers_enabled", false)
  load_balancing_algorithm_type      = lookup(var.target_group, "load_balancing_algorithm_type", null)

  dynamic "health_check" {
    for_each = length(keys(lookup(var.target_group, "health_check", {}))) == 0 ? [] : [lookup(var.target_group, "health_check", {})]

    content {
      enabled             = lookup(health_check.value, "enabled", null)
      interval            = lookup(health_check.value, "interval", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
      timeout             = lookup(health_check.value, "timeout", null)
      protocol            = lookup(health_check.value, "protocol", null)
      matcher             = lookup(health_check.value, "matcher", null)
    }
  }

  dynamic "stickiness" {
    for_each = length(keys(lookup(var.target_group, "stickiness", {}))) == 0 ? [] : [lookup(var.target_group, "stickiness", {})]

    content {
      enabled         = lookup(stickiness.value, "enabled", null)
      cookie_duration = lookup(stickiness.value, "cookie_duration", null)
      type            = lookup(stickiness.value, "type", null)
    }
  }

  tags = merge(
    var.tags,
    var.target_group_tags,
    lookup(var.target_group, "tags", {}),
    {
      "Name" = lookup(var.target_group, "name", lookup(var.target_group, "name_prefix", ""))
    },
  )

  

  lifecycle {
    create_before_destroy = true
  }
}

output "target_group_arns" {
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group."
  value       = aws_lb_target_group.main.*.arn
}

output "target_group_names" {
  description = "Name of the target group. Useful for passing to your CodeDeploy Deployment Group."
  value       = aws_lb_target_group.main.*.name
}

data "aws_vpc" "default" {
  id= "vpc-0ba9b1e62cf3650b7"
}


data "aws_instance" "this" {
  for_each = var.target_instance_names
  instance_tags = {
    Name = each.key
  }
}



resource "aws_alb_target_group_attachment" "this" {
for_each = var.target_instance_names
target_group_arn = data.aws_lb_target_group.this[each.key].arn
target_id = data.aws_instance.this[each.key].id
port = var.targets_traffic_port
}


data "aws_lb_target_group" "this" {
  for_each = var.target_instance_names
  name = each.value
  
}