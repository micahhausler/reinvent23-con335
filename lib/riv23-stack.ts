import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as s3 from 'aws-cdk-lib/aws-s3';

export class Riv23Stack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = new ec2.Vpc(this, "VPC", {
      ipAddresses: ec2.IpAddresses.cidr('10.0.0.0/16'),
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'ingress',
          subnetType: ec2.SubnetType.PUBLIC,
        },
      ],
    });

    // Tag VPC, SG, and Subnets
    cdk.Tags.of(vpc).add("kubernetes.io/cluster/blue-fish", "shared");
    cdk.Tags.of(vpc).add("kubernetes.io/cluster/red-fish", "shared");
    cdk.Tags.of(vpc).add("kubernetes.io/cluster/green-fish", "shared");
    cdk.Tags.of(vpc).add("kubernetes.io/cluster/gold-fish", "shared");

    const eksRole = new iam.Role(this, "ClusterRole", {
      assumedBy: new iam.ServicePrincipal("eks.amazonaws.com"),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonEKSClusterPolicy"),
      ]
    });

    const nodeRole = new iam.Role(this, "NodeRole", {
      assumedBy: new iam.ServicePrincipal("ec2.amazonaws.com"),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonEC2ContainerRegistryReadOnly"),
        iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonSSMManagedInstanceCore"),
        iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonEKS_CNI_Policy"),
        iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonEKSWorkerNodePolicy"),
      ],
      inlinePolicies: {
        // Permission for pod identity agent
        policy: new iam.PolicyDocument({ 
          statements: [
            new iam.PolicyStatement({
              actions: ["eks-auth:*"],
              effect: iam.Effect.ALLOW,
              resources: ["*"]
            })
          ]
        })
      }
    });

    const nodeInstanceProfile = new iam.InstanceProfile(this, "ReInvent23InstanceProfile", {
      role: nodeRole,
    })

    const bucket = new s3.Bucket(this, "ClusterBucket", {
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      enforceSSL: true,
      versioned: true,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    })

    const podRole = new iam.Role(this, "PodRole", {
      assumedBy: new iam.ServicePrincipal("pods.eks.amazonaws.com").withConditions(
        {
          "ArnEquals": {
            "aws:SourceArn": [
              `arn:aws:eks:us-west-2:${this.account}:cluster/blue-fish`,
              `arn:aws:eks:us-west-2:${this.account}:cluster/red-fish`
            ]
          }
        }
      ).withSessionTags(),
      inlinePolicies: {
        secretsmanagerPolicy: iam.PolicyDocument.fromJson({
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "AllActionsSecretsManagerSameCluster",
                  "Effect": "Allow",
                  "Action": "secretsmanager:*",
                  "Resource": "*",
                  "Condition": {
                      "StringEquals": {
                          "aws:ResourceTag/eks-cluster-name": "${aws:PrincipalTag/eks-cluster-name}",
                      },
                      "ForAllValues:StringEquals": {
                          "aws:TagKeys": [
                              "eks-cluster-name",
                          ]
                      },
                      "StringEqualsIfExists": {
                          "aws:RequestTag/eks-cluster-name": "${aws:PrincipalTag/eks-cluster-name}",
                      }
                  }
              },
              {
                  "Sid": "AllResourcesSecretsManagerNoTags",
                  "Effect": "Allow",
                  "Action": [
                      "secretsmanager:GetRandomPassword",
                      "secretsmanager:ListSecrets"
                  ],
                  "Resource": "*"
              },
              {
                  "Sid": "DenyUntagSecretsManagerReservedTags",
                  "Effect": "Deny",
                  "Action": "secretsmanager:UntagResource",
                  "Resource": "*",
                  "Condition": {
                      "ForAnyValue:StringLike": {
                          "aws:TagKeys": "eks-*"
                      }
                  }
              },
              {
                  "Sid": "DenyPermissionsManagement",
                  "Effect": "Deny",
                  "Action": "secretsmanager:*Policy",
                  "Resource": "*"
              }
          ]
         }),
        s3Policy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              actions: [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
              ],
              effect: iam.Effect.ALLOW,
              resources: [
                bucket.bucketArn + "/data/${aws:PrincipalTag/eks-cluster-name}/*",
                bucket.bucketArn + "/logs/${aws:PrincipalTag/kubernetes-pod-uid}/*",
                bucket.bucketArn + "/config/${aws:PrincipalTag/eks-cluster-name}/${aws:PrincipalTag/kubernetes-namespace}/${aws:PrincipalTag/kubernetes-service-account}/*",
              ]
            }),
            new iam.PolicyStatement({
              actions: [
                "s3:ListBucket",
              ],
              effect: iam.Effect.ALLOW,
              resources: [
                bucket.bucketArn
              ]
            }),
            new iam.PolicyStatement({
              actions: [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
              ],
              effect: iam.Effect.ALLOW,
              resources: ["*"]
            }),
          ]
        })
      },
    });
    cdk.Tags.of(podRole).add("reinvent-demo", "2023");

    const clusterViewRole = new iam.Role(this, "ClusterViewRole", {
      assumedBy: new iam.AccountPrincipal(this.account),
      roleName: "RIV23ClusterViewer"
    });
    const clusterViewRoleOutput = new cdk.CfnOutput(this, "viewRoleARN", {
      value: clusterViewRole.roleArn,
    });
    
    const clusterAdminRole = new iam.Role(this,"ClusterAdminRole", {
      assumedBy: new iam.AccountPrincipal(this.account),
      roleName: "RIV23ClusterAdmin"
    });
    const clusterAdminUserOutput = new cdk.CfnOutput(this, "adminRoleARN", {
      value: clusterAdminRole.roleArn,
    });

    const vpcIdOutput = new cdk.CfnOutput(this, "VpcID", {
      value: vpc.vpcId,
    });
    var subnetIds: string[] = [];
    vpc.publicSubnets.forEach(
      (subnet) => {
        subnetIds.push(subnet.subnetId);
      }
    );
    const subnetIdsOutput = new cdk.CfnOutput(this, "subnetIds", {
      value: cdk.Fn.join(",", subnetIds)
    });
    const clusterRoleOutput = new cdk.CfnOutput(this, "clusterRoleArnOutput", {
      value: eksRole.roleArn
    });
    const nodeRoleOutput = new cdk.CfnOutput(this, "nodeRoleArnOutput", {
      value: nodeRole.roleArn
    });
    const bucketNameOutput = new cdk.CfnOutput(this, "BucketNameOutput", {
      value: bucket.bucketName,
    });
    const podRoleOutput = new cdk.CfnOutput(this, "PodRoleOutput", {
      value: podRole.roleArn,
    })

  }
}
