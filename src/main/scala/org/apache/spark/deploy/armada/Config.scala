/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.spark.deploy.armada

import java.util.concurrent.TimeUnit
import org.apache.spark.internal.config.{ConfigBuilder, ConfigEntry, DRIVER_CORES, OptionalConfigEntry}
import org.apache.spark.network.util.ByteUnit

private[spark] object Config {
  val ARMADA_EXECUTOR_TRACKER_POLLING_INTERVAL: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.executor.trackerPollingInterval")
      .doc("Interval between polls to check the " +
        "state of executors.")
      .timeConf(TimeUnit.MILLISECONDS)
      .checkValue(interval => interval > 0, s"Polling interval must be a" +
        " positive time value.")
      .createWithDefaultString("60s")

  val ARMADA_EXECUTOR_TRACKER_TIMEOUT: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.executor.trackerTimeout")
      .doc("Time to wait for the minimum number of executors.")
      .timeConf(TimeUnit.MILLISECONDS)
      .checkValue(interval => interval > 0, s"Timeout must be a" +
        " positive time value.")
      .createWithDefaultString("600s")

  val ARMADA_LOOKOUTURL: ConfigEntry[String] =
    ConfigBuilder("spark.armada.lookouturl")
      .doc("URL base for the Armada Lookout UI.")
      .stringConf
      .checkValue(urlPrefix => urlPrefix.nonEmpty && urlPrefix.startsWith("http", 0),
        s"Value must be a valid URL, like http://host:8080 or https://host:443")
      .createWithDefaultString("http://localhost:30000")

  val ARMADA_HEALTH_CHECK_TIMEOUT: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.health.checkTimeout")
      .doc("Number of seconds to wait for an Armada health check result")
      .timeConf(TimeUnit.SECONDS)
      .checkValue(interval => interval > 0, s"Timeout must be a positive time value.")
      .createWithDefaultString("5")


  val ARMADA_QUEUE: ConfigEntry[String] =
    ConfigBuilder("spark.armada.queue")
      .doc("The Armada queue that will be used for running the driver and executor pods.")
      .version("1.0.0")
      .stringConf
      .createWithDefault("default")

  val ARMADA_JOB_SET_ID: ConfigEntry[String] =
    ConfigBuilder("spark.armada.job.set.id")
      .doc("The Armada job set id that will be used for running the driver and executor pods.")
      .version("1.0.0")
      .stringConf
      .createWithDefault("Armada-Spark-Job-Set")

  val ARMADA_NAMESPACE: ConfigEntry[String] =
    ConfigBuilder("spark.armada.namespace")
      .doc("The namespace that will be used for running the driver and executor pods.")
      .version("1.0.0")
      .stringConf
      .createWithDefault("default")

  val ARMADA_REMOTE_MASTER: OptionalConfigEntry[String] =
    ConfigBuilder("spark.armada.remote.master")
      .doc("The URL for the remote Armada master.")
      .version("1.0.0")
      .stringConf
      .createOptional


  val CONTAINER_IMAGE: OptionalConfigEntry[String] =
    ConfigBuilder("spark.armada.container.image")
      .doc("Container image to use for Spark containers. Individual container types " +
        "(e.g. driver or executor) can also be configured to use different images if desired, " +
        "by setting the container type-specific image name.")
      .version("1.0.0")
      .stringConf
      .createOptional

  val DRIVER_CONTAINER_IMAGE: ConfigEntry[Option[String]] =
    ConfigBuilder("spark.armada.driver.container.image")
      .doc("Container image to use for the driver.")
      .version("1.0.0")
      .fallbackConf(CONTAINER_IMAGE)

  val EXECUTOR_CONTAINER_IMAGE: ConfigEntry[Option[String]] =
    ConfigBuilder("spark.armada.executor.container.image")
      .doc("Container image to use for the executors.")
      .version("1.0.0")
      .fallbackConf(CONTAINER_IMAGE)

  val CONTAINER_IMAGE_PULL_POLICY: ConfigEntry[String] =
    ConfigBuilder("spark.armada.container.image.pullPolicy")
      .doc("Armada image pull policy. Valid values are Always, Never, and IfNotPresent.")
      .version("1.0.0")
      .stringConf
      .checkValues(Set("Always", "Never", "IfNotPresent"))
      .createWithDefault("IfNotPresent")

  val ARMADA_DRIVER_POD_NAME: OptionalConfigEntry[String] =
    ConfigBuilder("spark.armada.driver.pod.name")
      .doc("Name of the driver pod.")
      .version("1.0.0")
      .stringConf
      .createOptional

  val ARMADA_DRIVER_LIMIT_CORES: ConfigEntry[Int] =
    ConfigBuilder("spark.armada.driver.limit.cores")
      .doc("Specify the hard cpu limit for the driver pod")
      .version("1.0.0")
      .fallbackConf(DRIVER_CORES)

  val ARMADA_DRIVER_REQUEST_CORES: ConfigEntry[Int] =
    ConfigBuilder("spark.armada.driver.request.cores")
      .doc("Specify the cpu request for the driver pod")
      .version("1.0.0")
      .fallbackConf(DRIVER_CORES)

  val ARMADA_EXECUTOR_LIMIT_CORES: ConfigEntry[Int] =
    ConfigBuilder("spark.armada.executor.limit.cores")
      .doc("Specify the hard cpu limit for each executor pod")
      .version("1.0.0")
      .fallbackConf(DRIVER_CORES)

  val ARMADA_EXECUTOR_REQUEST_CORES: ConfigEntry[Int] =
    ConfigBuilder("spark.armada.executor.request.cores")
      .doc("Specify the cpu request for each executor pod")
      .version("1.0.0")
      .fallbackConf(DRIVER_CORES)

  val ARMADA_DRIVER_LIMIT_MEMORY: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.driver.limit.memory")
      .doc("Specify the hard memory limit for the driver pod")
      .version("1.0.0")
      .bytesConf(ByteUnit.MiB)
      .createWithDefaultString("450m")


  val ARMADA_DRIVER_REQUEST_MEMORY: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.driver.request.memory")
      .doc("Specify the memory request for the driver pod")
      .version("1.0.0")
      .bytesConf(ByteUnit.MiB)
      .createWithDefaultString("450m")


  val ARMADA_EXECUTOR_LIMIT_MEMORY: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.executor.limit.memory")
      .doc("Specify the hard memory limit for each executor pod")
      .version("1.0.0")
      .bytesConf(ByteUnit.MiB)
      .createWithDefaultString("450m")


  val ARMADA_EXECUTOR_REQUEST_MEMORY: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.executor.request.memory")
      .doc("Specify the memory request for each executor pod")
      .version("1.0.0")
      .bytesConf(ByteUnit.MiB)
      .createWithDefaultString("450m")


  val ARMADA_DRIVER_LIMIT_EPHEMERAL_STORAGE: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.driver.limit.ephemeral.storage")
      .doc("Specify the hard ephemeral storage limit for the driver pod")
      .version("1.0.0")
      .bytesConf(ByteUnit.MiB)
      .createWithDefaultString("512m")
  
  val ARMADA_DRIVER_REQUEST_EPHEMERAL_STORAGE: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.driver.request.ephemeral.storage")
      .doc("Specify the ephemeral storage request for the driver pod")
      .version("1.0.0")
      .bytesConf(ByteUnit.MiB)
      .createWithDefaultString("512m")

  val ARMADA_EXECUTOR_LIMIT_EPHEMERAL_STORAGE: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.executor.limit.ephemeral.storage")
      .doc("Specify the hard ephemeral storage limit for each executor pod")
      .version("1.0.0")
      .bytesConf(ByteUnit.MiB)
      .createWithDefaultString("512m")

  val ARMADA_EXECUTOR_REQUEST_EPHEMERAL_STORAGE: ConfigEntry[Long] =
    ConfigBuilder("spark.armada.executor.request.ephemeral.storage")
      .doc("Specify the ephemeral storage request for each executor pod")
      .version("1.0.0")
      .bytesConf(ByteUnit.MiB)
      .createWithDefaultString("512m")

}
