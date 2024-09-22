import { Injectable, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

/**
 * This is a Middleware is designed to log the incomming requests for debugging and analysis
 * METHOD + ROUTE
 */
@Injectable()
export class LogRequest implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const { baseUrl, headers, method, originalUrl } = req;
    console.log(`"${originalUrl}" - METHOD ${method}`);

    // with headers ${JSON.stringify(
    //   headers,
    // )}

    res.on('close', () => {
      // const respSent = res;
      // console.log(res, 'lets try');
    });

    next();
  }
}
