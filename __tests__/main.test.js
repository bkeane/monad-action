/**
 * Unit tests for the action's main functionality, src/main.js
 *
 * To mock dependencies in ESM, you can create fixtures that export mock
 * functions and objects. For example, the core module is mocked in this test,
 * so that the actual '@actions/core' module is not imported.
 */
import { jest } from '@jest/globals'
import * as core from '../__fixtures__/core.js'
import * as tc from '../__fixtures__/tool-cache.js'
import * as path from 'path'

// Mocks should be declared before the module being tested is imported.
jest.unstable_mockModule('@actions/core', () => core)
jest.unstable_mockModule('@actions/tool-cache', () => tc)
jest.unstable_mockModule('path', () => path)

// The module being tested should be imported dynamically. This ensures that the
// mocks are used in place of any actual dependencies.
const { run } = await import('../src/main.js')

describe('main.js', () => {
  beforeEach(() => {
    // Reset environment variables
    delete process.env.RUNNER_TOOL_CACHE
    delete process.env.RUNNER_TEMP

    // Set default mock implementations
    core.getInput.mockImplementation((name) => {
      switch (name) {
        case 'version':
          return 'v1.0.0'
        case 'ecr_registry_id':
          return '123456789'
        case 'ecr_registry_region':
          return 'us-west-2'
        case 'iam_permissions_boundary':
          return 'arn:aws:iam::123456789012:policy/boundary'
        default:
          return ''
      }
    })
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  describe('Environment setup', () => {
    it('Sets default tool cache and temp directories if not defined', async () => {
      // Ensure tool is not cached so env setup runs
      tc.find.mockReturnValueOnce(null)

      await run()

      expect(core.exportVariable).toHaveBeenCalledWith(
        'RUNNER_TOOL_CACHE',
        '/tmp/runner-tool-cache'
      )
      expect(core.exportVariable).toHaveBeenCalledWith(
        'RUNNER_TEMP',
        '/tmp/runner-temp'
      )
    })

    it('Preserves existing tool cache and temp directories', async () => {
      process.env.RUNNER_TOOL_CACHE = '/custom/cache'
      process.env.RUNNER_TEMP = '/custom/temp'
      await run()
      expect(core.exportVariable).not.toHaveBeenCalledWith(
        'RUNNER_TOOL_CACHE',
        expect.any(String)
      )
      expect(core.exportVariable).not.toHaveBeenCalledWith(
        'RUNNER_TEMP',
        expect.any(String)
      )
    })
  })

  describe('Tool installation', () => {
    it('Uses cached version if available', async () => {
      tc.find.mockReturnValueOnce('/cached/path')
      await run()
      expect(tc.find).toHaveBeenCalledWith('monad', 'v1.0.0')
      expect(core.addPath).toHaveBeenCalledWith('/cached/path')
      expect(tc.downloadTool).not.toHaveBeenCalled()
    })

    it('Downloads and installs tool if not cached', async () => {
      tc.find.mockReturnValueOnce(null)
      tc.downloadTool.mockResolvedValueOnce('/downloaded/path')
      tc.extractTar.mockResolvedValueOnce('/extracted/path')
      tc.cacheFile.mockResolvedValueOnce('/cached/path')

      await run()

      expect(tc.downloadTool).toHaveBeenCalled()
      expect(tc.extractTar).toHaveBeenCalled()
      expect(tc.cacheFile).toHaveBeenCalledWith(
        path.join('/extracted/path', 'monad'),
        'monad',
        'monad',
        'v1.0.0'
      )
      expect(core.addPath).toHaveBeenCalledWith('/cached/path')
    })
  })

  describe('Platform-specific behavior', () => {
    it('Handles Darwin platform correctly', async () => {
      tc.find.mockReturnValueOnce(null)
      Object.defineProperty(process, 'platform', { value: 'darwin' })
      Object.defineProperty(process, 'arch', { value: 'x64' })

      await run()

      expect(tc.downloadTool).toHaveBeenCalledWith(
        expect.stringContaining('monad_Darwin_x64.tar.gz')
      )
      expect(tc.extractTar).toHaveBeenCalled()
    })

    it('Handles Windows platform correctly', async () => {
      tc.find.mockReturnValueOnce(null)
      Object.defineProperty(process, 'platform', { value: 'win32' })
      Object.defineProperty(process, 'arch', { value: 'x64' })

      await run()

      expect(tc.downloadTool).toHaveBeenCalledWith(
        expect.stringContaining('monad_Win32_x64.zip')
      )
      expect(tc.extractZip).toHaveBeenCalled()
    })

    it('Fails on unsupported platform', async () => {
      Object.defineProperty(process, 'platform', { value: 'unsupported' })
      await run()
      expect(core.setFailed).toHaveBeenCalledWith(
        'Unsupported platform: Unsupported'
      )
    })
  })

  describe('Configuration', () => {
    it('Sets ECR configuration when provided', async () => {
      tc.find.mockReturnValueOnce('/cached/path')
      await run()
      const calls = core.exportVariable.mock.calls
      console.log('ECR config calls:', calls)
      expect(calls).toEqual(
        expect.arrayContaining([
          ['MONAD_ECR_REGISTRY_ID', '123456789'],
          ['MONAD_ECR_REGISTRY_REGION', 'us-west-2']
        ])
      )
    })

    it('Sets IAM permissions boundary when provided', async () => {
      tc.find.mockReturnValueOnce('/cached/path')
      await run()
      const calls = core.exportVariable.mock.calls
      console.log('IAM config calls:', calls)
      expect(calls).toEqual(
        expect.arrayContaining([
          [
            'MONAD_IAM_PERMISSIONS_BOUNDARY',
            'arn:aws:iam::123456789012:policy/boundary'
          ]
        ])
      )
    })

    it('Does not set optional configurations when not provided', async () => {
      tc.find.mockReturnValueOnce('/cached/path')
      core.getInput.mockImplementation((name) => {
        if (name === 'version') return 'v1.0.0'
        return ''
      })

      await run()
      const calls = core.exportVariable.mock.calls
      // Only tool cache variables should be set
      expect(calls).toEqual(
        expect.arrayContaining([
          ['RUNNER_TOOL_CACHE', '/tmp/runner-tool-cache'],
          ['RUNNER_TEMP', '/tmp/runner-temp']
        ])
      )
      // Should NOT contain ECR or IAM variables
      calls.forEach((call) => {
        expect([
          'MONAD_ECR_REGISTRY_ID',
          'MONAD_ECR_REGISTRY_REGION',
          'MONAD_IAM_PERMISSIONS_BOUNDARY'
        ]).not.toContain(call[0])
      })
    })
  })

  describe('Error handling', () => {
    it('Handles download errors', async () => {
      tc.find.mockReturnValueOnce(null)
      Object.defineProperty(process, 'platform', { value: 'darwin' })
      Object.defineProperty(process, 'arch', { value: 'x64' })
      const error = new Error('Download failed')
      tc.downloadTool.mockRejectedValueOnce(error)

      await run()
      expect(core.setFailed).toHaveBeenCalledWith('Download failed')
    })

    it('Handles extraction errors', async () => {
      tc.find.mockReturnValueOnce(null)
      Object.defineProperty(process, 'platform', { value: 'darwin' })
      Object.defineProperty(process, 'arch', { value: 'x64' })
      tc.downloadTool.mockResolvedValueOnce('/downloaded/path')
      const error = new Error('Extraction failed')
      tc.extractTar.mockRejectedValueOnce(error)

      await run()
      expect(core.setFailed).toHaveBeenCalledWith('Extraction failed')
    })
  })
})
