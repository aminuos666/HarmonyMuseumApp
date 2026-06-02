/**
 * HTTP 客户端工具
 *
 * 封装 @ohos.net.http，提供统一的 GET/POST/PUT/DELETE 请求，
 * 自动附加 JWT Token，统一错误处理。
 *
 * ─── 使用方式 ───
 *   const http = HttpClient.getInstance();
 *   const data = await http.get<ArtworkOut>('/api/artworks/por_001');
 *
 * ─── baseUrl 说明 ───
 *   模拟器：http://10.0.2.2:8000
 *   真机调试：http://<你的电脑IP>:8000
 *   生产环境：https://your-domain.com
 */
import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import { Constants } from '../utils/Constants';

class HttpClientError {
  code: number = 0;
  message: string = '';
}

export class HttpClient {
  private static instance: HttpClient;
  private baseUrl: string;
  private token: string = '';

  private constructor() {
    // 默认使用 Constants 中配置的 API 地址
    // 模拟器：http://10.0.2.2:8000
    // 真机调试：http://<电脑IP>:8000
    this.baseUrl = Constants.API_BASE_URL;
  }

  static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient();
    }
    return HttpClient.instance;
  }

  /** 修改 API 基础地址（真机调试时需改为电脑 IP） */
  setBaseUrl(url: string): void {
    this.baseUrl = url;
  }

  getBaseUrl(): string {
    return this.baseUrl;
  }

  /** 设置 JWT Token */
  setToken(token: string): void {
    this.token = token;
  }

  getToken(): string {
    return this.token;
  }

  clearToken(): void {
    this.token = '';
  }

  isLoggedIn(): boolean {
    return this.token.length > 0;
  }

  // ──────── 请求头 ────────

  private buildHeaders(contentType?: string): Record<string, string> {
    const headers: Record<string, string> = {};
    headers['Content-Type'] = contentType || 'application/json';
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    return headers;
  }

  // ──────── HTTP 方法 ────────

  async get<T>(path: string, params?: Record<string, string>): Promise<T> {
    let url = `${this.baseUrl}${path}`;
    if (params) {
      const parts: string[] = [];
      const paramKeys = Object.keys(params);
      for (const k of paramKeys) {
        const v = params[k];
        if (v !== undefined && v !== null) {
          parts.push(`${encodeURIComponent(k)}=${encodeURIComponent(v)}`);
        }
      }
      if (parts.length > 0) {
        url += `?${parts.join('&')}`;
      }
    }

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: this.buildHeaders(),
        connectTimeout: 15000,
        readTimeout: 15000,
      });
      return this.handleResponse<T>(response);
    } catch (e) {
      throw new Error(`GET ${path} 失败: ${(e as Error).message}`);
    } finally {
      httpRequest.destroy();
    }
  }

  async post<T>(path: string, body?: Record<string, Object>): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const httpRequest = http.createHttp();
    try {
      const reqOptions: Record<string, Object> = {} as Record<string, Object>;
      reqOptions['method'] = http.RequestMethod.POST;
      reqOptions['header'] = this.buildHeaders();
      reqOptions['connectTimeout'] = 15000;
      reqOptions['readTimeout'] = 15000;
      if (body) {
        reqOptions['extraData'] = JSON.stringify(body);
      }
      const response = await httpRequest.request(url, reqOptions);
      return this.handleResponse<T>(response);
    } catch (e) {
      throw new Error(`POST ${path} 失败: ${(e as Error).message}`);
    } finally {
      httpRequest.destroy();
    }
  }

  async put<T>(path: string, body?: Record<string, Object>): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const httpRequest = http.createHttp();
    try {
      const reqOptions: Record<string, Object> = {} as Record<string, Object>;
      reqOptions['method'] = http.RequestMethod.PUT;
      reqOptions['header'] = this.buildHeaders();
      reqOptions['connectTimeout'] = 15000;
      reqOptions['readTimeout'] = 15000;
      if (body) {
        reqOptions['extraData'] = JSON.stringify(body);
      }
      const response = await httpRequest.request(url, reqOptions);
      return this.handleResponse<T>(response);
    } catch (e) {
      throw new Error(`PUT ${path} 失败: ${(e as Error).message}`);
    } finally {
      httpRequest.destroy();
    }
  }

  async delete<T>(path: string): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.DELETE,
        header: this.buildHeaders(),
        connectTimeout: 15000,
        readTimeout: 15000,
      });
      return this.handleResponse<T>(response);
    } catch (e) {
      throw new Error(`DELETE ${path} 失败: ${(e as Error).message}`);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 上传文件（multipart/form-data）
   * 以图搜图等场景使用
   *
   * @param path API 路径，如 '/api/image-search'
   * @param fileUri 文件 URI（来自 photoAccessHelper.PhotoViewPicker 或 cameraPicker）
   * @param fieldName 表单字段名，默认 'file'
   */
  async uploadFile<T>(path: string, fileUri: string, fieldName: string = 'file'): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const httpRequest = http.createHttp();
    try {
      const uploadHeaders: Record<string, string> = {
        'Content-Type': 'multipart/form-data',
      };
      if (this.token) {
        uploadHeaders['Authorization'] = `Bearer ${this.token}`;
      }
      const reqOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: uploadHeaders,
        multiFormDataList: [
          {
            name: fieldName,
            filePath: fileUri,
            contentType: 'image/jpeg',
            remoteFileName: 'photo.jpg',
          }
        ],
        connectTimeout: 30000,
        readTimeout: 60000,
      };
      const response: http.HttpResponse = await httpRequest.request(url, reqOptions);
      return this.handleResponse<T>(response);
    } catch (e) {
      const eObj = e as BusinessError;
      const errMsg = eObj.message || `code=${eObj.code}` || JSON.stringify(e);
      throw new Error(`UPLOAD ${path} 失败: ${errMsg}`);
    } finally {
      httpRequest.destroy();
    }
  }

  // ──────── 响应处理 ────────

  private handleResponse<T>(response: http.HttpResponse): T {
    const code = response.responseCode;
    const raw = response.result as string;

    if (code >= 200 && code < 300) {
      try {
        return JSON.parse(raw) as T;
      } catch (e) {
        // 部分接口返回非 JSON（如空响应）
        return JSON.parse(raw) as T;
      }
    }

    let message = `HTTP ${code}`;
    try {
      const errBody = JSON.parse(raw) as Record<string, string>;
      message = errBody['detail'] || errBody['message'] || message;
    } catch (_) {
      // 解析失败就使用默认消息
    }

    if (code === 401) {
      // Token 过期或无效，清除登录状态
      this.clearToken();
      message = '登录已过期，请重新登录';
    }

    throw new Error(message);
  }
}
