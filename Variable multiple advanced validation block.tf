variable "os" {
  default = "Linux"
}

variable "application_stack" {
  type = object({
    dotnet_version              = optional(string)
    use_dotnet_isolated_runtime = optional(bool)
    java_version                = optional(string)
    node_version                = optional(string)
    python_version              = optional(string)
    powershell_core_version     = optional(string)
    use_custom_runtime          = optional(bool)
  })
  default = {
    dotnet_version              = null
    use_dotnet_isolated_runtime = false #null
    java_version                = null
    node_version                = 12
    python_version              = null
    powershell_core_version     = null
    use_custom_runtime          = false
  }

  # Validation for .NET version
  validation {
    condition = (
      var.application_stack.dotnet_version == null || (
        (var.os == "Linux" && (var.application_stack.dotnet_version == null || can(regex("^(3\\.1|6\\.0|7\\.0|8\\.0)$", var.application_stack.dotnet_version))))
        ) || (
        (var.os == "Windows" && (var.application_stack.dotnet_version == null || can(regex("^(3\\.0|4\\.0|6\\.0|7\\.0|8\\.0)$", var.application_stack.dotnet_version))))
      )
    )
    error_message = "If specified, .NET version must be one of 3.1, 6.0, 7.0, or 8.0 for Linux. Windows versions are possible values include v3.0, v4.0 v6.0, v7.0 and v8.0. Defaults to v4.0"
  }

  validation {
    condition     = can(var.application_stack.use_dotnet_isolated_runtime) && (var.os == "Linux" || var.os == "Windows")
    error_message = "Should the DotNet process use an isolated runtime, The 'use_dotnet_isolated_runtime' must be a boolean value, accepted true or false. Defaults to false"
  }

  validation {
    condition = (
      var.application_stack.java_version == null || (
        var.os == "Linux" && can(regex("^(8|11|17)$", var.application_stack.java_version))
        ) || (
        var.os == "Windows" && can(regex("^(1\\.8|11|17)$", var.application_stack.java_version))
      )
    )
    error_message = "The version of Java to use. Linux supported versions include 8, 11 & 17. For Windows supported versions include 1.8, 11 & 17 (In-Preview)."
  }

  validation {
    condition = (
      var.application_stack.node_version == null || (
        lower(var.os) == "linux" && can(regex("^(12|14|16|18|20)$", var.application_stack.node_version))
        ) || (
        lower(var.os) == "windows" && can(regex("^(~12|~14|~16|~18|~20)$", var.application_stack.node_version))
      )
    )
    error_message = "The version of Node to run. Possible values include 12, 14, 16, 18, and 20 for Linux. Possible values include ~12, ~14, ~16, ~18, and ~20 for Windows."
  }

  # validation {
  #     condition = var.application_stack.python == "" || (
  #       var.application_stack.python != "" && (
  #         var.application_stack.python in ["3.7", "3.8", "3.9", "3.10", "3.11"]
  #       )
  #     )
  #     error_message = "For Python, only versions 3.7 to 3.11 are supported."
  #   }

  validation {
    condition = var.application_stack.python_version == null || (
      lower(var.os) == "Linux" && can(regex("^(3\\.12|3\\.11|3\\.10|3\\.9|3\\.8|3\\.7)$", var.application_stack.python_version))
    )
    error_message = var.os == "Windows" ? "Windows is not supported" : "The version of Python to run. Possible values for Linux are 3.12, 3.11, 3.10, 3.9, 3.8 and 3.7."
  }

  # validation {
  #   condition = var.application_stack.python_version == null || (
  #     lower(var.os) == "linux" && can(regex("^(3\\.12|3\\.11|3\\.10|3\\.9|3\\.8|3\\.7)$", var.application_stack.python_version))
  #   )
  #   error_message = lower(var.os) == "windows" ? "Python versions are only supported on Linux. Please set the OS to Linux or remove the Python version." : "The Python version is invalid. Supported versions for Linux are 3.12, 3.11, 3.10, 3.9, 3.8, and 3.7."
  # }


  validation {
    condition = var.application_stack.powershell_core_version == null || (
      lower(var.os) == "linux" && can(regex("^(7|7\\.2|7\\.4)$", var.application_stack.powershell_core_version))
      ) || (
      lower(var.os) == "windows" && can(regex("^(7|7\\.2|7\\.4)$", var.application_stack.powershell_core_version))
    )
    error_message = "he version of PowerShell Core to run. Windows and Linux Possible values are 7, 7.2, and 7.4"
  }

  validation {
    condition     = can(var.application_stack.use_custom_runtime) && (var.os == "Linux" || var.os == "Windows")
    error_message = "Should the Linux Function App use a custom runtime?, The 'use_custom_runtime ' must be a boolean value, accepted true or false. Defaults to false"
  }

  validation {
    condition = (
      (
        (
          length([for known_stack01 in [
            var.application_stack.dotnet_version,
            var.application_stack.java_version,
            var.application_stack.node_version,
            var.application_stack.python_version,
            var.application_stack.powershell_core_version
          ] : known_stack01 if known_stack01 != null]) == 1
          ) && (
          length([for unknown_stack01 in [
            var.application_stack.use_dotnet_isolated_runtime,
            var.application_stack.use_custom_runtime
          ] : unknown_stack01 if unknown_stack01 == true]) == 0
        )
        ) || (
        (
          length([for known_stack01 in [
            var.application_stack.dotnet_version,
            var.application_stack.java_version,
            var.application_stack.node_version,
            var.application_stack.python_version,
            var.application_stack.powershell_core_version
          ] : known_stack01 if known_stack01 != null]) == 0
          ) && (
          length([for unknown_stack01 in [
            var.application_stack.use_dotnet_isolated_runtime,
            var.application_stack.use_custom_runtime
          ] : unknown_stack01 if unknown_stack01 == true]) == 1
        )
      )

    )
    error_message = "Only one runtime version or isolated runtime option can be set at a time."
  }
}