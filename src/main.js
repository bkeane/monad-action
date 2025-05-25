import * as core from '@actions/core'
import * as tc from '@actions/tool-cache'
import * as path from 'path'

/**
 * The main function for the action.
 *
 * @returns {Promise<void>} Resolves when the action is complete.
 */
export async function run() {
  if (process.env.RUNNER_TOOL_CACHE === undefined) {
    core.exportVariable('RUNNER_TOOL_CACHE', '/tmp/runner-tool-cache')
  }

  if (process.env.RUNNER_TEMP === undefined) {
    core.exportVariable('RUNNER_TEMP', '/tmp/runner-temp')
  }

  try {
    const version = core.getInput('version')
    core.info(`Installing monad version ${version}...`)

    // Check if the tool is already cached
    let cachedPath = tc.find('monad', version)
    if (cachedPath) {
      core.info(`Found cached monad version ${version}`)
      core.addPath(cachedPath)
    } else {
      const platform = process.platform
      const releasePlatform =
        platform.charAt(0).toUpperCase() + platform.slice(1)
      const releaseArch = process.arch == 'x64' ? 'x86_64' : process.arch
      var url
      let extractedPath

      if (releasePlatform === 'Darwin' || releasePlatform === 'Linux') {
        url = `https://github.com/bkeane/monad/releases/download/${version}/monad_${releasePlatform}_${releaseArch}.tar.gz`
        core.info(`Downloading monad from ${url}...`)
        const downloadPath = await tc.downloadTool(url)
        extractedPath = await tc.extractTar(downloadPath)
      } else if (releasePlatform === 'Win32') {
        url = `https://github.com/bkeane/monad/releases/download/${version}/monad_${releasePlatform}_${releaseArch}.zip`
        core.info(`Downloading monad from ${url}...`)
        const downloadPath = await tc.downloadTool(url)
        extractedPath = await tc.extractZip(downloadPath)
      } else {
        core.setFailed(
          `Unsupported release: monad_${releasePlatform}_${releaseArch}.tar.gz`
        )
        return
      }

      // Find the executable in the extracted path
      const executablePath = path.join(extractedPath, 'monad')

      // Cache the tool
      cachedPath = await tc.cacheFile(executablePath, 'monad', 'monad', version)
    }

    // Add the cached tool to the PATH
    core.addPath(cachedPath)
    core.info(`Successfully installed monad version ${version}`)

    const ecrRegistryId = core.getInput('ecr_registry_id')
    const ecrRegistryRegion = core.getInput('ecr_registry_region')
    const iamPermissionsBoundary = core.getInput('iam_permissions_boundary')

    if (ecrRegistryId) {
      core.info(`Pointing monad to ECR registry ID: ${ecrRegistryId}`)
      core.exportVariable('MONAD_ECR_REGISTRY_ID', ecrRegistryId)
    }

    if (ecrRegistryRegion) {
      core.info(`Pointing monad to ECR registry region: ${ecrRegistryRegion}`)
      core.exportVariable('MONAD_ECR_REGISTRY_REGION', ecrRegistryRegion)
    }

    if (iamPermissionsBoundary) {
      core.info(
        `Monad will apply ${iamPermissionsBoundary} IAM permissions boundary to managed roles`
      )
      core.exportVariable(
        'MONAD_IAM_PERMISSIONS_BOUNDARY',
        iamPermissionsBoundary
      )
    }
  } catch (error) {
    // Fail the workflow run if an error occurs
    if (error instanceof Error) core.setFailed(error.message)
  }
}
