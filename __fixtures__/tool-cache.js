/**
 * Mock implementation of @actions/tool-cache
 */
import { jest } from '@jest/globals'

export const find = jest.fn()
export const downloadTool = jest.fn()
export const extractTar = jest.fn()
export const extractZip = jest.fn()
export const cacheFile = jest.fn()

// Reset all mocks
export const resetMocks = () => {
  find.mockReset()
  downloadTool.mockReset()
  extractTar.mockReset()
  extractZip.mockReset()
  cacheFile.mockReset()
} 