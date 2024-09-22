import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { LogRequest } from './middleware';
import { PrismaService } from './prisma/prisma.service';
import { PrismaModule } from './prisma/prisma.module';
import { AppController } from './app/app.controller';
import { AppService } from './app/app.service';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { CoreModule } from './core/core.module';

/**
 * Root Of the APP with request logging middleware implemented
 *  @alias ServeStaticModule used for serving this docs over (docs)[/docs] Documentation is generated in `documentation` file
 * @alias ConfigModule usedas Configservice to retrieve env elements
 * @alias CacheModule used to init reddis cache store with ttl 1200 `20min`
 */
@Module({
  imports: [
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', 'documentation'),
      serveRoot: '/docs', // this will serve your files on /docs route
    }),

    ConfigModule.forRoot({
      isGlobal: true,
    }),
    PrismaModule,
    CoreModule,
  ],
  providers: [PrismaService, AppService],
  controllers: [AppController],
})
export class AppModule implements NestModule {
  /**
   * Configuring the middleware for routes
   * @alias LogRequest middleware logs type of request and route
   */
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LogRequest).forRoutes('*');
  }
}
